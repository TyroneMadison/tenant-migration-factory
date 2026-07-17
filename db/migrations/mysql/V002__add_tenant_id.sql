-- Single-tenant to pooled multi-tenant conversion, step 1:
-- every row gets an owner. Backfill happens per-tenant during import,
-- so the columns arrive nullable and are tightened in V003.

ALTER TABLE customers
    ADD COLUMN tenant_id VARCHAR(32) NULL AFTER id;

ALTER TABLE work_orders
    ADD COLUMN tenant_id VARCHAR(32) NULL AFTER id;

CREATE INDEX ix_customers_tenant ON customers (tenant_id);
CREATE INDEX ix_work_orders_tenant ON work_orders (tenant_id, status);
