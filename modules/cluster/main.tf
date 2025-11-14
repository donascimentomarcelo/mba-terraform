data "aws_secretsmanager_secret" "main" {
  arn = "arn:aws:secretsmanager:us-east-1:462839258964:secret:prod/Terraform/Db-qbASJq"
}

data "aws_secretsmanager_secret_version" "main" {
  secret_id = data.aws_secretsmanager_secret.main.id
}

resource "aws_instance" "main" {
  count                  = var.instance_count
  ami                    = "ami-0157af9aea2eef346"
  instance_type          = "t3.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_id

  user_data = <<EOF
#!/bin/bash
DB_STRING="Server=${jsondecode(data.aws_secretsmanager_secret_version.main.secret_string)["Host"]};DB=${jsondecode(data.aws_secretsmanager_secret_version.main.secret_string)["DB"]};

echo $DB_STRING > test.txt
EOF

  tags = {
    Name = "${var.prefix}-bastion-host ${count.index + 1}"
  }
}

# resource "aws_eip" "main" { //elastic ip address
#   instance   = aws_instance.main.id
#   depends_on = [aws_internet_gateway.main]
# }

# resource "aws_ssm_parameter" "main" { //ssm parameter store
#   name  = "vm_ip"
#   type  = "String"
#   value = aws_eip.main.public_ip
#   tags = {
#     Name = "vm_ip"
#   }
# }
