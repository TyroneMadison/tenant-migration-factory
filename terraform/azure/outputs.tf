output "web_app_hostname" {
  description = "Public entry point for the shared application tier"
  value       = module.app.default_hostname
}

output "sql_server_fqdn" {
  description = "FQDN of the pooled tenant database server"
  value       = module.database.server_fqdn
}
