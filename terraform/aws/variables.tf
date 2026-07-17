variable "region" {
  description = "AWS region for the shared platform"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "staging", "prod"], var.environment)
    error_message = "environment must be one of dev, qa, staging, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the platform VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used by the platform subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "Instance type for the shared application tier"
  type        = string
  default     = "t3.micro"
}

variable "app_min_size" {
  description = "Minimum instances in the application auto scaling group"
  type        = number
  default     = 2
}

variable "app_max_size" {
  description = "Maximum instances in the application auto scaling group"
  type        = number
  default     = 6
}

variable "db_instance_class" {
  description = "RDS instance class for the pooled tenant database"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for the pooled tenant database"
  type        = number
  default     = 100
}

variable "db_multi_az" {
  description = "Enable multi-AZ for the pooled tenant database"
  type        = bool
  default     = false
}

variable "tenants" {
  description = "Tenant registry: tenants onboard as data, not as new infrastructure"
  type = map(object({
    tier        = string
    routing_key = string
  }))
  default = {}
}
