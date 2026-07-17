"""Load and validate tenant definitions against the JSON schema.

Every migration decision downstream (wave planning, tfvars rendering,
cutover checklists) trusts the data loaded here, so validation is strict
and failures are loud.
"""

from __future__ import annotations

import json
from pathlib import Path

import yaml
from jsonschema import Draft7Validator


class TenantValidationError(Exception):
    """Raised when a tenant file does not conform to the schema."""

    def __init__(self, path: str, errors: list[str]):
        self.path = path
        self.errors = errors
        joined = "; ".join(errors)
        super().__init__(f"{path}: {joined}")


def load_schema(schema_path: Path) -> dict:
    with open(schema_path, encoding="utf-8") as fh:
        return json.load(fh)


def validate_tenant(data: dict, schema: dict, path: str = "<memory>") -> dict:
    """Validate a single tenant document. Returns the document on success."""
    validator = Draft7Validator(schema)
    problems = sorted(validator.iter_errors(data), key=lambda e: list(e.path))
    if problems:
        messages = [
            f"{'/'.join(str(p) for p in err.path) or '<root>'}: {err.message}"
            for err in problems
        ]
        raise TenantValidationError(path, messages)
    return data


def load_tenants(tenants_dir: Path, schema_path: Path | None = None) -> list[dict]:
    """Load every tenant YAML file in a directory, validated and sorted by id."""
    tenants_dir = Path(tenants_dir)
    if schema_path is None:
        schema_path = tenants_dir / "schema.json"
    schema = load_schema(schema_path)

    tenants: list[dict] = []
    for yaml_path in sorted(tenants_dir.glob("*.yaml")):
        with open(yaml_path, encoding="utf-8") as fh:
            data = yaml.safe_load(fh)
        validate_tenant(data, schema, path=str(yaml_path))
        tenants.append(data)

    return sorted(tenants, key=lambda t: t["tenant"]["id"])
