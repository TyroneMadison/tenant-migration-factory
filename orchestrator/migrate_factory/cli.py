"""Command line interface for the Tenant Migration Factory."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from . import __version__
from .checklist import render_markdown
from .renderer import write_tfvars
from .tenant_loader import TenantValidationError, load_tenants
from .wave_planner import format_waves, plan_waves


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="migrate-factory",
        description="Tenant-as-code migration orchestration for AWS and Azure.",
    )
    parser.add_argument("--version", action="version", version=__version__)
    parser.add_argument(
        "--tenants-dir",
        default="tenants",
        help="Directory holding tenant YAML files and schema.json",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("validate", help="Validate every tenant file against the schema")

    waves = sub.add_parser("plan-waves", help="Print risk-scored migration waves")
    waves.add_argument("--wave-size", type=int, default=2)

    render = sub.add_parser("render", help="Render per-tenant tfvars json")
    render.add_argument("--output", default="rendered")

    checklist = sub.add_parser("checklist", help="Print a cutover checklist")
    checklist.add_argument("tenant_id")

    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    tenants_dir = Path(args.tenants_dir)

    try:
        tenants = load_tenants(tenants_dir)
    except TenantValidationError as err:
        print(f"VALIDATION FAILED: {err}", file=sys.stderr)
        return 2

    if args.command == "validate":
        print(f"OK: {len(tenants)} tenant definition(s) valid")
        return 0

    if args.command == "plan-waves":
        print(format_waves(plan_waves(tenants, wave_size=args.wave_size)))
        return 0

    if args.command == "render":
        for tenant in tenants:
            path = write_tfvars(tenant, Path(args.output))
            print(f"rendered {path}")
        return 0

    if args.command == "checklist":
        for tenant in tenants:
            if tenant["tenant"]["id"] == args.tenant_id:
                print(render_markdown(tenant))
                return 0
        print(f"unknown tenant id: {args.tenant_id}", file=sys.stderr)
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
