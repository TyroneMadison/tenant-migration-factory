# Zero to minimal downtime database cutover

The pattern below keeps the customer-facing outage inside a 30 minute
budget even for large databases, because the bulk copy happens before the
window ever opens.

## Sequence

1. T-7 days: restore the latest full backup to the target and start
   continuous replay (log shipping for SQL Server, binlog replication or
   AWS DMS for MySQL).
2. T-1 day: run the reconciliation report. Row counts, checksums on hot
   tables, and max timestamps must match within replication lag.
3. T-0, window opens: put the source application in read-only mode.
4. Replay the final log tail. This is minutes, not hours, because only the
   tail is left.
5. Run migrations V002 and V003 style steps if the tenant is entering the
   pooled schema, then backfill tenant_id for the imported rows.
6. Flip application configuration to the target connection string via the
   tenant registry. No code deploy is involved.
7. Smoke test, then shift traffic 10 percent, then 100 percent via
   weighted DNS.
8. Keep the source in read-only mode for the rollback horizon (48 hours).

## Rollback triggers

* Error rate above 1 percent for 5 sustained minutes after cutover.
* Reconciliation mismatch on any financially significant table.
* Replication lag that cannot drain inside the window.

Rollback is a configuration flip back to the source connection string
while the source is still read-only, followed by a scheduled retry.
