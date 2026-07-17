provider "aws" {
  region = var.region

  default_tags {
    tags = {
      project     = "tenant-migration-factory"
      environment = var.environment
      managed_by  = "terraform"
    }
  }
}
