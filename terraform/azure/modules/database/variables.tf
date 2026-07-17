variable "name_prefix" {
  description = "Prefix applied to all database resources"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for database resources"
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
  description = "Azure SQL database SKU"
  type        = string
  default     = "S0"
}

variable "max_size_gb" {
  description = "Maximum database size in GB"
  type        = number
  default     = 50
}
