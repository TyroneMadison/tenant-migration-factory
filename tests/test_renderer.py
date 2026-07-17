import json

from migrate_factory.renderer import REQUIRED_KEYS, render_tfvars, write_tfvars


def test_render_contains_required_keys(sample_tenant):
    payload = render_tfvars(sample_tenant)
    for key in REQUIRED_KEYS:
        assert key in payload
    assert payload["tenant_id"] == "test-tenant"
    assert payload["compliance_flags"] == []


def test_write_tfvars_lands_in_cloud_env_path(tmp_path, sample_tenant):
    out = write_tfvars(sample_tenant, tmp_path)
    assert out.name == "test-tenant.auto.tfvars.json"
    assert out.parent == tmp_path / "aws" / "prod"
    data = json.loads(out.read_text())
    assert data["db_engine"] == "mysql"
