-- Baseline schema for the pooled platform database (SQL Server / Azure SQL).

CREATE TABLE dbo.customers (
    id            BIGINT IDENTITY (1, 1) PRIMARY KEY,
    display_name  NVARCHAR(120) NOT NULL,
    created_at    DATETIME2 NOT NULL CONSTRAINT df_customers_created DEFAULT SYSUTCDATETIME()
);

CREATE TABLE dbo.work_orders (
    id            BIGINT IDENTITY (1, 1) PRIMARY KEY,
    customer_id   BIGINT NOT NULL,
    status        NVARCHAR(24) NOT NULL CONSTRAINT df_work_orders_status DEFAULT N'open',
    payload       NVARCHAR(MAX) NOT NULL,
    created_at    DATETIME2 NOT NULL CONSTRAINT df_work_orders_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT fk_work_orders_customer
        FOREIGN KEY (customer_id) REFERENCES dbo.customers (id)
);

CREATE INDEX ix_work_orders_status ON dbo.work_orders (status);
