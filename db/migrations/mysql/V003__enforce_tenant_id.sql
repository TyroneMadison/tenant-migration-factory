-- Single-tenant to pooled multi-tenant conversion, step 2:
-- once every imported row is backfilled, tenant_id becomes mandatory.
-- Application queries are already tenant-scoped by this point.

ALTER TABLE customers
    MODIFY COLUMN tenant_id VARCHAR(32) NOT NULL;

ALTER TABLE work_orders
    MODIFY COLUMN tenant_id VARCHAR(32) NOT NULL;
