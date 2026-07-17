from migrate_factory.checklist import build_checklist, render_markdown


def test_windows_sqlserver_tenant_gets_extra_steps(sample_tenant):
    sample_tenant["source"]["os"] = "windows"
    sample_tenant["database"]["engine"] = "sqlserver"
    steps = "\n".join(build_checklist(sample_tenant))
    assert "Test-MigrationReadiness.ps1" in steps
    assert "compatibility level" in steps


def test_tight_downtime_prestages_restore(sample_tenant):
    sample_tenant["database"]["downtime_budget_minutes"] = 15
    steps = "\n".join(build_checklist(sample_tenant))
    assert "Pre-stage" in steps


def test_markdown_renders_checkboxes(sample_tenant):
    md = render_markdown(sample_tenant)
    assert md.startswith("# Cutover checklist: test-tenant")
    assert "- [ ]" in md
