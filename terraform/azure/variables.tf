variable "location" {
  description = "Azure region for the shared platform"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "staging", "prod"], var.environment)
    error_message = "environment must be one of dev, qa, staging, prod."
  }
}

variable "vnet_cidr" {
  description = "Address space for the platform virtual network"
  type        = string
  default     = "10.30.0.0/16"
}

variable "app_sku" {
  description = "App Service plan SKU for the shared application tier"
  type        = string
  default     = "B1"
}

variable "db_sku" {
  description = "Azure SQL SKU for the pooled tenant database"
  type        = string
  default     = "S0"
}

variable "db_max_size_gb" {
  description = "Maximum size of the pooled tenant database in GB"
  type        = number
  default     = 50
}

variable "tenants" {
  description = "Tenant registry: tenants onboard as data, not as new infrastructure"
  type = map(object({
    tier        = string
    routing_key = string
  }))
  default = {}
}
