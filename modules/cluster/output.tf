output "private_dns" {
  value = aws_instance.main[0].private_dns
}
