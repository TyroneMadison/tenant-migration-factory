variable "name_prefix" {
  description = "Prefix applied to all application resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC hosting the application tier"
  type        = string
}

variable "public_subnet_ids" {
  description = "Subnets for the load balancer"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Subnets for application instances"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type for application nodes"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum size of the auto scaling group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum size of the auto scaling group"
  type        = number
  default     = 6
}
