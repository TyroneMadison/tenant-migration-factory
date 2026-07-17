locals {
  name_prefix = "tmf-${var.environment}"
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "platform" {
  name     = "rg-${local.name_prefix}"
  location = var.location

  tags = {
    project     = "tenant-migration-factory"
    environment = var.environment
    managed_by  = "terraform"
  }
}

module "network" {
  source = "./modules/network"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
  vnet_cidr           = var.vnet_cidr
}

module "app" {
  source = "./modules/app"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
  suffix              = random_string.suffix.result
  sku_name            = var.app_sku
  environment         = var.environment

  # The heart of the model: the tenant registry ships to the shared app
  # tier as configuration, so onboarding a tenant is a data change.
  tenants = var.tenants
}

module "database" {
  source = "./modules/database"

  name_prefix         = local.name_prefix
  resource_group_name = azurerm_resource_group.platform.name
  location            = azurerm_resource_group.platform.location
  suffix              = random_string.suffix.result
  sku_name            = var.db_sku
  max_size_gb         = var.db_max_size_gb
}
