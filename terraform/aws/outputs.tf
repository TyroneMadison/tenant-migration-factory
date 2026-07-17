output "alb_dns_name" {
  description = "Public entry point for the shared application tier"
  value       = module.app.alb_dns_name
}

output "db_endpoint" {
  description = "Endpoint of the pooled tenant database"
  value       = module.database.endpoint
}

output "tenant_parameter_names" {
  description = "SSM parameter names holding the tenant registry"
  value       = [for p in aws_ssm_parameter.tenant_registry : p.name]
}
