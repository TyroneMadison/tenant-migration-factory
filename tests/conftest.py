import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "orchestrator"))

import pytest  # noqa: E402


@pytest.fixture
def tenants_dir() -> Path:
    return REPO_ROOT / "tenants"


@pytest.fixture
def sample_tenant() -> dict:
    return {
        "tenant": {"id": "test-tenant", "name": "Test Tenant", "tier": "standard"},
        "source": {"platform": "aws", "os": "linux", "region": "us-east-1"},
        "target": {"cloud": "aws", "environment": "prod", "region": "us-east-1"},
        "database": {"engine": "mysql", "size_gb": 10, "downtime_budget_minutes": 240},
        "cutover": {"window": "anytime"},
    }
