-- Baseline schema for the pooled platform database (MySQL 8.0).
-- Versioned migrations follow Flyway naming: V<version>__<description>.sql

CREATE TABLE customers (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    display_name  VARCHAR(120) NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;

CREATE TABLE work_orders (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id   BIGINT UNSIGNED NOT NULL,
    status        VARCHAR(24) NOT NULL DEFAULT 'open',
    payload       JSON NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_work_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (id)
) ENGINE = InnoDB;

CREATE INDEX ix_work_orders_status ON work_orders (status);
