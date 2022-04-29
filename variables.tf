variable "aws_region" {
  type        = string
  description = "AWS region name."
}

variable "environment_name" {
  type = string
  description = "Use this as value for Name Tag for resources."
  default = "cloud-dev-env"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.10.10.0/27"
  description = "The CIDR block for VPC. /28 is minimum subnet."
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources."
  default     = {}
}