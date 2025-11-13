terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.49.0"
    }
  }
}

data "aws_secretsmanager_secret" "main" {
  arn = "arn:aws:secretsmanager:us-east-1:462839258964:secret:prod/Terraform/Db-qbASJq"
}

data "aws_secretsmanager_secret_version" "main" {
  secret_id = data.aws_secretsmanager_secret.main.id
}

provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_instance" "main" {
  ami                    = "ami-0157af9aea2eef346"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main.id]

  user_data = <<EOF
#!/bin/bash
DB_STRING="Server=${jsondecode(data.aws_secretsmanager_secret_version.main.secret_string)["Host"]};DB=${jsondecode(data.aws_secretsmanager_secret_version.main.secret_string)["DB"]};

echo $DB_STRING > test.txt
EOF
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main"
  }
}

resource "aws_eip" "main" { //elastic ip address
  instance   = aws_instance.main.id
  depends_on = [aws_internet_gateway.main]
}

resource "aws_ssm_parameter" "main" { //ssm parameter store
  name  = "vm_ip"
  type  = "String"
  value = aws_eip.main.public_ip
  tags = {
    Name = "vm_ip"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "main"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "main" {
  name        = "Allow SSH"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "main" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "main" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

output "private_dns" {
  value = aws_instance.main.private_dns
}

output "eip" {
  value = aws_eip.main.public_ip
}
