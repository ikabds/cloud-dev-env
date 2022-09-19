provider "aws" {
  region = var.aws_region
  access_key = "${var.secrets.aws_access_key_id}"
  secret_key = "${var.secrets.aws_secret_access_key}"
  token      = "${var.secrets.aws_session_token}"
  default_tags {
    tags = var.tags
  }
}