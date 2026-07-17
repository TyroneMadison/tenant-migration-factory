# Wave strategy

Migrating a hundred single-tenant environments is a scheduling problem
disguised as an engineering problem. The wave planner turns it into code.

## Scoring

Each tenant gets a transparent risk score. The weights live at the top of
orchestrator/migrate_factory/wave_planner.py where a code review can
challenge them:

| Signal | Weight |
| --- | --- |
| Source platform on-prem | +40 |
| Source platform cloud | +15 |
| Windows workload | +10 |
| SQL Server engine | +10 |
| Database over 100 GB | +20 |
| Database over 25 GB | +10 |
| Each compliance flag (ITAR, CUI, FedRAMP) | +15 |
| Downtime budget under 60 minutes | +10 |

## Rules

1. Lowest risk migrates first. Early waves build muscle memory and prove
   the runbooks while the blast radius is small.
2. Compliance-flagged tenants never ride in wave 1. The landing zone
   controls get exercised on plain tenants before regulated data moves.
3. Wave size is a dial, not a constant. Start at 2, raise it as cutovers
   become boring.

## Why this matters

The expensive failure mode in tenant migrations is not a bad script, it
is a bad sequence: dragging the hardest customer into the first weekend,
burning the team, and losing organizational trust in the whole program.
Sequencing by scored risk keeps wins early and compounding.
