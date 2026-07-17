output "server_fqdn" {
  value = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "database_id" {
  value = azurerm_mssql_database.pooled.id
}
