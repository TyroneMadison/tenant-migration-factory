variable "name_prefix" {
  description = "Prefix applied to all network resources"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for network resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_cidr" {
  description = "Address space for the virtual network"
  type        = string
}
