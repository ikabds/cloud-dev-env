output "instance_id" {
    value = data.aws_instance.this.id
}

output "ssm_bucket_name" {
    value = local.ansible_aws_ssm_bucket_name
}