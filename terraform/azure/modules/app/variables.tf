variable "name_prefix" {
  description = "Prefix applied to all app resources"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for app resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "suffix" {
  description = "Random suffix for globally unique names"
  type        = string
}

variable "sku_name" {
  description = "App Service plan SKU"
  type        = string
  default     = "B1"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
}

variable "tenants" {
  description = "Tenant registry delivered to the app as configuration"
  type = map(object({
    tier        = string
    routing_key = string
  }))
  default = {}
}
