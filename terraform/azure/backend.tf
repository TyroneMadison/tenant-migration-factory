# Remote state lives in an Azure Storage container. Supply the environment
# specific settings at init time:
#   terraform init -backend-config=envs/prod.backend.hcl
terraform {
  backend "azurerm" {}
}
