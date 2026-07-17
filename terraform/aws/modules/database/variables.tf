variable "name_prefix" {
  description = "Prefix applied to all database resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC hosting the database tier"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the database subnet group"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group of the application tier"
  type        = string
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
  default     = false
}
