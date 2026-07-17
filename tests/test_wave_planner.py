import copy

from migrate_factory.wave_planner import format_waves, plan_waves, risk_score


def _tenant(tenant_id, platform="aws", os="linux", engine="mysql", size=10,
            budget=240, compliance=None):
    return {
        "tenant": {"id": tenant_id, "name": tenant_id, "tier": "standard"},
        "source": {"platform": platform, "os": os},
        "target": {"cloud": "aws", "environment": "prod"},
        "database": {
            "engine": engine,
            "size_gb": size,
            "downtime_budget_minutes": budget,
        },
        "cutover": {"window": "anytime", **({"compliance": compliance} if compliance else {})},
    }


def test_onprem_windows_sqlserver_scores_highest():
    easy, _ = risk_score(_tenant("easy"))
    hard, reasons = risk_score(
        _tenant("hard", platform="onprem", os="windows", engine="sqlserver",
                size=180, budget=30, compliance=["itar", "cui"])
    )
    assert hard > easy
    assert any("onprem" in r for r in reasons)
    assert any("compliance" in r for r in reasons)


def test_waves_ordered_by_ascending_risk():
    tenants = [
        _tenant("small"),
        _tenant("medium", size=60),
        _tenant("large-onprem", platform="onprem", size=200),
    ]
    waves = plan_waves(tenants, wave_size=1)
    flat = [item["id"] for wave in waves for item in wave]
    assert flat == ["small", "medium", "large-onprem"]


def test_compliance_tenants_never_in_wave_one():
    tenants = [
        _tenant("plain-a"),
        _tenant("plain-b", size=60),
        _tenant("flagged-tiny", compliance=["cui"]),
    ]
    waves = plan_waves(tenants, wave_size=2)
    wave_one_ids = [item["id"] for item in waves[0]]
    assert "flagged-tiny" not in wave_one_ids
    later_ids = [item["id"] for wave in waves[1:] for item in wave]
    assert "flagged-tiny" in later_ids


def test_all_compliance_yields_burn_in_wave():
    tenants = [_tenant("only-flagged", compliance=["fedramp"])]
    waves = plan_waves(tenants, wave_size=2)
    assert waves[0] == []
    assert waves[1][0]["id"] == "only-flagged"
    rendered = format_waves(waves)
    assert "burn-in" in rendered


def test_wave_size_respected():
    tenants = [_tenant(f"t{i}") for i in range(5)]
    waves = plan_waves(tenants, wave_size=2)
    assert [len(w) for w in waves] == [2, 2, 1]
