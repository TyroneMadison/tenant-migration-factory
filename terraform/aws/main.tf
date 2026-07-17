locals {
  name_prefix = "tmf-${var.environment}"
}

module "network" {
  source = "./modules/network"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "app" {
  source = "./modules/app"

  name_prefix        = local.name_prefix
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  instance_type      = var.instance_type
  min_size           = var.app_min_size
  max_size           = var.app_max_size
}

module "database" {
  source = "./modules/database"

  name_prefix           = local.name_prefix
  vpc_id                = module.network.vpc_id
  private_subnet_ids    = module.network.private_subnet_ids
  app_security_group_id = module.app.app_security_group_id
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  multi_az              = var.db_multi_az
}

# The heart of the model: onboarding tenant 101 is a one-line map entry,
# not a new environment. Application instances read the registry at boot.
resource "aws_ssm_parameter" "tenant_registry" {
  for_each = var.tenants

  name  = "/${local.name_prefix}/tenants/${each.key}"
  type  = "String"
  value = jsonencode(each.value)

  tags = {
    tenant = each.key
    tier   = each.value.tier
  }
}
