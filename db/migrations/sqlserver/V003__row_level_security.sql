-- Single-tenant to pooled multi-tenant conversion, step 2:
-- Row-Level Security so a tenant can never read another tenant's rows,
-- even if an application bug drops the WHERE clause.

CREATE SCHEMA rls;
GO

CREATE FUNCTION rls.fn_tenant_predicate (@tenant_id NVARCHAR(32))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS allowed
    WHERE @tenant_id = CAST(SESSION_CONTEXT(N'tenant_id') AS NVARCHAR(32));
GO

CREATE SECURITY POLICY rls.tenant_isolation
    ADD FILTER PREDICATE rls.fn_tenant_predicate(tenant_id) ON dbo.customers,
    ADD FILTER PREDICATE rls.fn_tenant_predicate(tenant_id) ON dbo.work_orders
    WITH (STATE = ON);
GO

-- The application sets the tenant per connection:
--   EXEC sp_set_session_context @key = N'tenant_id', @value = @CurrentTenant;
