variable "name_prefix" {
  description = "Prefix applied to all network resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for subnet placement"
  type        = list(string)
}
