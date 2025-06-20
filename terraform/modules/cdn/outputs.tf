# Salidas del módulo de CDN

output "cloudfront_distribution_id" {
  description = "El ID de la distribución de CloudFront."
  value       = aws_cloudfront_distribution.s3_distribution.id
}

output "cloudfront_distribution_domain_name" {
  description = "El nombre de dominio de la distribución de CloudFront (para acceder al sitio)."
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "cloudfront_distribution_arn" {
  description = "El ARN de la distribución de CloudFront."
  value       = aws_cloudfront_distribution.s3_distribution.arn
}