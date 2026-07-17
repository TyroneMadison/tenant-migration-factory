"""Risk-scored wave planning.

The goal is simple: migrate the cheap, low-risk tenants first to prove the
pipeline, and schedule the heavy, compliance-bound, on-prem tenants into
later waves once the landing zone and runbooks have mileage on them.
"""

from __future__ import annotations

# Score weights are intentionally transparent. Tuning them is a code review,
# not a guess buried in a spreadsheet.
PLATFORM_RISK = {"onprem": 40, "azure": 15, "aws": 15}
WINDOWS_RISK = 10
SQLSERVER_RISK = 10
SIZE_RISK_LARGE = 20   # over 100 GB
SIZE_RISK_MEDIUM = 10  # over 25 GB
COMPLIANCE_RISK_PER_FLAG = 15
TIGHT_DOWNTIME_RISK = 10  # under 60 minutes of allowed downtime


def risk_score(tenant: dict) -> tuple[int, list[str]]:
    """Return (score, reasons) for one tenant definition."""
    score = 0
    reasons: list[str] = []

    platform = tenant["source"]["platform"]
    score += PLATFORM_RISK[platform]
    reasons.append(f"source platform {platform} (+{PLATFORM_RISK[platform]})")

    if tenant["source"].get("os") == "windows":
        score += WINDOWS_RISK
        reasons.append(f"windows workload (+{WINDOWS_RISK})")

    if tenant["database"]["engine"] == "sqlserver":
        score += SQLSERVER_RISK
        reasons.append(f"sql server engine (+{SQLSERVER_RISK})")

    size_gb = tenant["database"]["size_gb"]
    if size_gb > 100:
        score += SIZE_RISK_LARGE
        reasons.append(f"database {size_gb} GB (+{SIZE_RISK_LARGE})")
    elif size_gb > 25:
        score += SIZE_RISK_MEDIUM
        reasons.append(f"database {size_gb} GB (+{SIZE_RISK_MEDIUM})")

    flags = tenant["cutover"].get("compliance", [])
    if flags:
        bump = COMPLIANCE_RISK_PER_FLAG * len(flags)
        score += bump
        reasons.append(f"compliance flags {','.join(flags)} (+{bump})")

    budget = tenant["database"].get("downtime_budget_minutes")
    if budget is not None and budget < 60:
        score += TIGHT_DOWNTIME_RISK
        reasons.append(f"downtime budget {budget} min (+{TIGHT_DOWNTIME_RISK})")

    return score, reasons


def _summarize(tenant: dict) -> dict:
    score, reasons = risk_score(tenant)
    return {
        "id": tenant["tenant"]["id"],
        "name": tenant["tenant"]["name"],
        "target": tenant["target"]["cloud"],
        "score": score,
        "reasons": reasons,
        "compliance": bool(tenant["cutover"].get("compliance")),
    }


def _chunk(items: list[dict], size: int) -> list[list[dict]]:
    return [items[i : i + size] for i in range(0, len(items), size)]


def plan_waves(tenants: list[dict], wave_size: int = 2) -> list[list[dict]]:
    """Group tenants into migration waves ordered by ascending risk.

    Rules:
    * Lower risk migrates earlier.
    * Any tenant carrying compliance flags (ITAR, CUI, FedRAMP) is never
      scheduled in wave 1. The landing zone controls get proven on plain
      tenants before regulated data moves.
    * If every tenant is compliance-flagged, wave 1 is returned empty on
      purpose: it becomes a landing zone burn-in wave.
    """
    if wave_size < 1:
        raise ValueError("wave_size must be at least 1")

    scored = sorted(
        (_summarize(t) for t in tenants),
        key=lambda item: (item["score"], item["id"]),
    )
    plain = [item for item in scored if not item["compliance"]]
    flagged = [item for item in scored if item["compliance"]]

    waves: list[list[dict]] = [plain[:wave_size]]
    remaining = sorted(
        plain[wave_size:] + flagged,
        key=lambda item: (item["score"], item["id"]),
    )
    waves.extend(_chunk(remaining, wave_size))
    return waves


def format_waves(waves: list[list[dict]]) -> str:
    lines = []
    for index, wave in enumerate(waves, start=1):
        lines.append(f"Wave {index}")
        if not wave:
            lines.append("  (empty: landing zone burn-in, no tenants scheduled)")
        for item in wave:
            lines.append(
                f"  {item['id']:<20} risk {item['score']:>3}  target {item['target']}"
            )
            for reason in item["reasons"]:
                lines.append(f"      - {reason}")
    return "\n".join(lines)
