variable "aws_region" {
  type        = string
  description = "AWS region name."
}

variable "environment_name" {
  type        = string
  description = "Use this as value for Name Tag for resources."
  default     = "cloud-dev-env"
}

variable "existing_s3_bucket_name" {
  type        = string
  description = "In not empty use existing S3 bucket for SSM. Recommended as ansible has bug with S3 unavailable though SSM first 24 hours."
  default     = ""
}

variable "vpc_cidr" {
  type        = string
  default     = "10.10.10.0/27"
  description = "The CIDR block for VPC. /28 is minimum subnet."
}

variable "versions" {
  type        = map(string)
  description = "Versions of tools"
  default = {
    helm_version       = "3.8.2"
    kubectl_version    = "1.23.6"
    terraform_version  = "1.1.9"
    terragrunt_version = "0.36.9"
  }
}

variable "configs" {
  type        = map(string)
  description = "Configs of tools"
  default = {
    public_key_path = "~/.ssh/id_rsa.pub"
  }
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources."
  default     = {}
}