locals {
    subnets_cidr = cidrsubnets(var.vpc_cidr, 1, 1)
}

resource "aws_vpc" "this" {
  cidr_block       = var.vpc_cidr
  tags             = {
      Name = var.environment_name
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.subnets_cidr[0]
  tags             = {
      Name = var.environment_name
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_eip" "nat" {
  vpc      = true
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

resource "aws_route_table" "public" {
  vpc_id   = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = {
      Name = var.environment_name
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.subnets_cidr[1]
  tags             = {
      Name = var.environment_name
  }
}

resource "aws_route_table" "private" {
  vpc_id   = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0" # Traffic from Private Subnet reaches Internet via NAT Gateway
    nat_gateway_id = aws_nat_gateway.this.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_iam_role" "ssm" {
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
  tags = {
      Name = var.environment_name
  }
}

resource "aws_iam_instance_profile" "cloud9" {
  name = "AWSCloud9SSMInstanceProfile"
  path = "/cloud9/"
  role = aws_iam_role.ssm.name
}

resource "aws_cloud9_environment_ec2" "this" {
  instance_type = "t3.small"
  name          = var.environment_name
  image_id      = "ubuntu-18.04-x86_64"
  subnet_id     = aws_subnet.private.id
  automatic_stop_time_minutes = 60
  connection_type = "CONNECT_SSM"
  
  depends_on = [
    aws_iam_instance_profile.cloud9,
    aws_nat_gateway.this
  ]
}