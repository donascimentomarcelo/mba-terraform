output "subnet_id" {
  value = values(aws_subnet.main)[*].id
}

output "security_group_id" {
  value = aws_security_group.main.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}
