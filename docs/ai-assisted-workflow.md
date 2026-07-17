# AI-assisted engineering workflow

This repository is deliberately built the way modern platform teams are
starting to work: AI agents generate and refactor, deterministic checks
and human review decide what merges.

## The loop

1. Describe the change in terms of the tenant contract or module
   boundary, for example: add a downtime budget signal to wave scoring.
2. Let the AI pair (Claude Code or similar) draft the module change, the
   test change, and the doc change together.
3. Deterministic gates run locally and in CI: pytest, schema validation
   of every tenant file, and terraform validate on both cloud stacks.
4. Human review focuses on intent and blast radius, not syntax.

## Why CLAUDE.md exists

CLAUDE.md encodes the repo contract for AI agents: what the source of
truth is, what never gets committed, and which commands must pass before
a change is proposed. Teams that write this contract down get consistent
output from AI tooling. Teams that do not, get drift with extra steps.

## Where AI earns its keep here

* Generating mirrored Terraform changes across the AWS and Azure stacks.
* Writing pytest cases for edge conditions (all tenants compliance
  flagged, empty wave one burn-in).
* Drafting cutover checklists and runbooks from the tenant schema.
* Explaining a failing terraform validate in plain language during review.
