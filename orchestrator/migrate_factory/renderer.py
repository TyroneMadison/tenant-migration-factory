"""Render tenant definitions into Terraform-ready tfvars documents.

The Terraform stacks stay generic. Everything tenant-specific arrives as
data, which is what makes onboarding tenant 101 identical to tenant 1.
"""

from __future__ import annotations

import json
from pathlib import Path

REQUIRED_KEYS = ("tenant_id", "tier", "environment", "db_engine")


def render_tfvars(tenant: dict) -> dict:
    """Build the auto.tfvars payload for one tenant."""
    return {
        "tenant_id": tenant["tenant"]["id"],
        "tenant_name": tenant["tenant"]["name"],
        "tier": tenant["tenant"]["tier"],
        "environment": tenant["target"]["environment"],
        "region": tenant["target"].get("region", ""),
        "db_engine": tenant["database"]["engine"],
        "db_size_gb": tenant["database"]["size_gb"],
        "compliance_flags": tenant["cutover"].get("compliance", []),
    }


def write_tfvars(tenant: dict, output_root: Path) -> Path:
    """Write rendered tfvars under rendered/<cloud>/<environment>/."""
    payload = render_tfvars(tenant)
    cloud = tenant["target"]["cloud"]
    env = tenant["target"]["environment"]
    out_dir = Path(output_root) / cloud / env
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{payload['tenant_id']}.auto.tfvars.json"
    with open(out_path, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2, sort_keys=True)
        fh.write("\n")
    return out_path
