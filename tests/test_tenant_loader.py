import copy

import pytest

from migrate_factory.tenant_loader import (
    TenantValidationError,
    load_schema,
    load_tenants,
    validate_tenant,
)


def test_sample_tenants_all_valid(tenants_dir):
    tenants = load_tenants(tenants_dir)
    assert len(tenants) == 3
    ids = [t["tenant"]["id"] for t in tenants]
    assert ids == sorted(ids)


def test_missing_required_block_fails(tenants_dir, sample_tenant):
    schema = load_schema(tenants_dir / "schema.json")
    broken = copy.deepcopy(sample_tenant)
    del broken["database"]
    with pytest.raises(TenantValidationError) as excinfo:
        validate_tenant(broken, schema, path="broken.yaml")
    assert "database" in str(excinfo.value)


def test_bad_enum_fails(tenants_dir, sample_tenant):
    schema = load_schema(tenants_dir / "schema.json")
    broken = copy.deepcopy(sample_tenant)
    broken["target"]["cloud"] = "gcp"
    with pytest.raises(TenantValidationError):
        validate_tenant(broken, schema)


def test_unknown_key_fails(tenants_dir, sample_tenant):
    schema = load_schema(tenants_dir / "schema.json")
    broken = copy.deepcopy(sample_tenant)
    broken["surprise"] = True
    with pytest.raises(TenantValidationError):
        validate_tenant(broken, schema)
