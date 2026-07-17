resource "random_password" "sql_admin" {
  length  = 24
  special = true
}

resource "azurerm_mssql_server" "this" {
  name                = "sql-${var.name_prefix}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = "12.0"

  administrator_login          = "platformadmin"
  administrator_login_password = random_password.sql_admin.result
  minimum_tls_version          = "1.2"

  # Production deployments front this with Private Link. The firewall rule
  # below only allows Azure backbone services during migration rehearsals.
  public_network_access_enabled = true
}

resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_mssql_database" "pooled" {
  name        = "sqldb-${var.name_prefix}-pooled"
  server_id   = azurerm_mssql_server.this.id
  sku_name    = var.sku_name
  max_size_gb = var.max_size_gb

  # Every table in the pooled schema carries tenant_id. See db/migrations.
}
