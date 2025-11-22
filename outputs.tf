output "s3_bucket_arn" {
  description = "ARN do bucket S3 terraform-mba"
  value       = data.aws_s3_bucket.terraform_mba.arn
}

output "s3_bucket_id" {
  description = "ID do bucket S3 terraform-mba"
  value       = data.aws_s3_bucket.terraform_mba.id
}

output "s3_bucket_domain_name" {
  description = "Nome de domínio do bucket S3 terraform-mba"
  value       = data.aws_s3_bucket.terraform_mba.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "Nome de domínio regional do bucket S3 terraform-mba"
  value       = data.aws_s3_bucket.terraform_mba.bucket_regional_domain_name
}

