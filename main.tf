data "aws_caller_identity" "current" {}

locals {
  subnets_cidr                = cidrsubnets(var.vpc_cidr, 1, 1)
  s3_bucket_generated_name    = "cloud9-${var.environment_name}-${data.aws_caller_identity.current.account_id}-ssm"
  ansible_aws_ssm_bucket_name = var.existing_s3_bucket_name != "" ? var.existing_s3_bucket_name : local.s3_bucket_generated_name
}

resource "aws_s3_bucket" "ssm" {
  count  = var.existing_s3_bucket_name != "" ? 0 : 1
  bucket = local.ansible_aws_ssm_bucket_name
  tags = merge({
    Name = var.environment_name
  }, var.tags)
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = merge({
    Name = var.environment_name
  }, var.tags)
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.this.id
  cidr_block = local.subnets_cidr[0]
  tags = merge({
    Name = var.environment_name
  }, var.tags)
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = merge({
    Name = var.environment_name
  }, var.tags)
}

resource "aws_eip" "nat" {
  vpc = true
  tags = merge({
    Name = var.environment_name
  }, var.tags)
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = merge({
    Name = var.environment_name
  }, var.tags)
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge({
    Name = var.environment_name
  }, var.tags)
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.this.id
  cidr_block = local.subnets_cidr[1]
  tags = merge({
    Name = var.environment_name
  }, var.tags)
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0" # Traffic from Private Subnet reaches Internet via NAT Gateway
    nat_gateway_id = aws_nat_gateway.this.id
  }
  tags = merge({
    Name = var.environment_name
  }, var.tags)
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_iam_role" "ssm" {
  count = var.skip_service_role_creation ? 0 : 1

  name = "AWSCloud9SSMAccessRole"
  path = "/service-role/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com",
                    "cloud9.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSCloud9SSMInstanceProfile",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
  tags = merge({
    Name = var.environment_name
  }, var.tags)
}

resource "aws_iam_instance_profile" "cloud9" {
  count = var.skip_instance_profile_creation ? 0 : 1

  name = "AWSCloud9SSMInstanceProfile"
  path = "/cloud9/"
  role = var.skip_service_role_creation ? "AWSCloud9SSMAccessRole" : aws_iam_role.ssm[0].name
  tags = merge({
    Name = var.environment_name
  }, var.tags)
}

resource "aws_cloud9_environment_ec2" "this" {
  instance_type               = var.instance_type
  name                        = var.environment_name
  image_id                    = "amazonlinux-2-x86_64"
  subnet_id                   = aws_subnet.private.id
  automatic_stop_time_minutes = 60
  connection_type             = "CONNECT_SSM"

  depends_on = [
    aws_iam_instance_profile.cloud9,
    aws_nat_gateway.this
  ]

  tags = var.tags
}

data "aws_instance" "this" {
  filter {
    name = "tag:aws:cloud9:environment"
    values = [
    aws_cloud9_environment_ec2.this.id]
  }
}

resource "null_resource" "ansible" {

  triggers = merge(
    { for yml in fileset(path.module, "ansible/tools/**.yml") : yml => sha256(file(yml)) },
    {
      plabook_sha = sha256(file("ansible/playbook.yml")),
      instance_id = data.aws_instance.this.id,
      vars        = sha256(file("terraform.tfvars.json"))

    },
    var.versions
  )

  provisioner "local-exec" {
    command = <<EOF
OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES \
ANSIBLE_KEEP_REMOTE_FILES=1 \
ansible-playbook \
-i "${data.aws_instance.this.id}," \
-e ansible_python_interpreter=python3 \
${join(" ", [for tool in keys(var.versions) : format("-e \"%s='%s'\"", tool, var.versions[tool])])} \
${join(" ", [for conf in keys(var.configs) : format("-e \"%s='%s'\"", conf, var.configs[conf])])} \
${join(" ", [for secret in keys(var.secrets) : format("-e \"%s='%s'\"", secret, var.secrets[secret])])} \
-e "{\"repositories\": ${jsonencode(var.repositories)}}" \
-e aws_region=${var.aws_region} \
-e ansible_aws_ssm_bucket_name=${local.ansible_aws_ssm_bucket_name} \
ansible/playbook.yml
EOF
  }
}