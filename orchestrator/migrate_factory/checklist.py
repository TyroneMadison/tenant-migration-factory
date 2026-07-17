"""Generate a cutover checklist tailored to one tenant.

A checklist nobody has to rewrite by hand for each customer is the
difference between migrating 3 tenants a quarter and 3 tenants a night.
"""

from __future__ import annotations

BASE_STEPS = [
    "Confirm stakeholder sign-off and change ticket approval",
    "Verify latest backup completed and restore-tested",
    "Enable dual-write or replication from source to target database",
    "Deploy tenant configuration to target platform (terraform apply)",
    "Run smoke tests against target environment",
    "Shift 10 percent of traffic via weighted DNS and watch error rates",
    "Shift 100 percent of traffic after 30 clean minutes",
    "Freeze source environment (read-only)",
    "Run post-cutover data reconciliation report",
    "Schedule source environment decommission (T+14 days)",
]

WINDOWS_STEPS = [
    "Run powershell/Test-MigrationReadiness.ps1 against the source host",
    "Capture Windows service inventory and scheduled tasks",
]

SQLSERVER_STEPS = [
    "Verify SQL Server compatibility level against target",
    "Script logins, jobs, and linked servers (they do not travel with backups)",
    "Rehearse restore timing: backup, copy, restore, log tail",
]

COMPLIANCE_STEPS = [
    "Confirm data residency and boundary controls for flagged data",
    "File evidence artifacts for the compliance audit trail",
    "Verify access reviews completed for target environment",
]

TIGHT_WINDOW_STEPS = [
    "Pre-stage full backup restore on target ahead of the window",
    "Use log shipping or CDC so cutover only replays the tail",
]


def build_checklist(tenant: dict) -> list[str]:
    steps = list(BASE_STEPS)

    if tenant["source"].get("os") == "windows":
        steps = WINDOWS_STEPS + steps
    if tenant["database"]["engine"] == "sqlserver":
        steps = SQLSERVER_STEPS + steps
    if tenant["cutover"].get("compliance"):
        steps = COMPLIANCE_STEPS + steps
    budget = tenant["database"].get("downtime_budget_minutes")
    if budget is not None and budget < 60:
        steps = TIGHT_WINDOW_STEPS + steps

    return steps


def render_markdown(tenant: dict) -> str:
    tenant_id = tenant["tenant"]["id"]
    window = tenant["cutover"]["window"]
    lines = [
        f"# Cutover checklist: {tenant_id}",
        "",
        f"Window: {window} | Target: {tenant['target']['cloud']} "
        f"{tenant['target']['environment']}",
        "",
    ]
    lines += [f"- [ ] {step}" for step in build_checklist(tenant)]
    lines.append("")
    return "\n".join(lines)
