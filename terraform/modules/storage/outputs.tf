# Salidas del módulo de storage

output "s3_bucket_id" {
  description = "El ID (nombre) del bucket S3 creado."
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_arn" {
  description = "El ARN (Amazon Resource Name) del bucket S3."
  value       = aws_s3_bucket.website.arn
}

output "s3_bucket_regional_domain_name" {
  description = "El nombre de dominio regional del bucket, usado por CloudFront como origen."
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}