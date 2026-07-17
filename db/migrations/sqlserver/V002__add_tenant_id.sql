-- Single-tenant to pooled multi-tenant conversion, step 1: ownership columns.

ALTER TABLE dbo.customers ADD tenant_id NVARCHAR(32) NULL;
ALTER TABLE dbo.work_orders ADD tenant_id NVARCHAR(32) NULL;
GO

CREATE INDEX ix_customers_tenant ON dbo.customers (tenant_id);
CREATE INDEX ix_work_orders_tenant ON dbo.work_orders (tenant_id, status);
GO
