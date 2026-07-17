# Working in this repository (humans and AI agents)

This project is built AI-first: modules, tests, and docs are generated and
refactored with AI pair engineering tools, then reviewed and validated by
a human before merge. If you are an AI agent, follow the same contract.

## Layout

* tenants/ holds the single source of truth. One YAML file per tenant,
  validated by tenants/schema.json. Never invent fields, extend the schema
  first.
* orchestrator/ is a stdlib-plus-PyYAML Python package. Keep it dependency
  light on purpose.
* terraform/aws and terraform/azure are parallel stacks with matching
  module boundaries (network, app, database). A change to one side usually
  needs a mirror change on the other.
* db/migrations are Flyway-named and forward-only. Never edit an applied
  migration, add a new version.

## Guardrails

* Run make test and make validate before proposing any change.
* Never commit state files, credentials, or rendered tfvars.
* Tenant YAML changes must keep the orchestrator green: schema validation
  is the contract with the platform.
* Terraform changes must pass terraform validate in both stacks.
* Keep module inputs explicit. No provider blocks inside modules.

## Validation commands

    make test          # pytest suite for the orchestrator
    make validate      # schema-check every tenant definition
    make waves         # print the current wave plan
    make tf-validate   # terraform validate both stacks (requires terraform)
