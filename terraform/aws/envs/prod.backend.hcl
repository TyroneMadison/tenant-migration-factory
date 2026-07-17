bucket         = "tmf-terraform-state-prod"
key            = "platform/aws/prod/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "tmf-terraform-locks"
encrypt        = true
