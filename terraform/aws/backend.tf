# Remote state lives in S3 with DynamoDB locking. Supply the environment
# specific settings at init time:
#   terraform init -backend-config=envs/prod.backend.hcl
terraform {
  backend "s3" {}
}
