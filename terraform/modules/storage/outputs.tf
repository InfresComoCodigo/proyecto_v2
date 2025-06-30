###################################################################
# OUTPUTS PARA MÓDULO STORAGE (S3)
###################################################################

###################################################################
# S3 BUCKET OUTPUTS
###################################################################

output "bucket_id" {
  description = "ID del bucket S3"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.main.arn
}

output "bucket_name" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.main.bucket
}

output "bucket_domain_name" {
  description = "Nombre de dominio del bucket S3"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Nombre de dominio regional del bucket S3"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "bucket_hosted_zone_id" {
  description = "Zone ID del bucket S3 para Route 53"
  value       = aws_s3_bucket.main.hosted_zone_id
}

output "bucket_region" {
  description = "Región del bucket S3"
  value       = aws_s3_bucket.main.region
}

###################################################################
# CLOUDFRONT ORIGIN ACCESS CONTROL
###################################################################

output "cloudfront_oac_id" {
  description = "ID del Origin Access Control de CloudFront"
  value       = aws_cloudfront_origin_access_control.main.id
}

output "cloudfront_oac_etag" {
  description = "ETag del Origin Access Control de CloudFront"
  value       = aws_cloudfront_origin_access_control.main.etag
}

###################################################################
# CONFIGURACIÓN DE ACCESO
###################################################################

output "bucket_policy" {
  description = "Política del bucket S3"
  value       = aws_s3_bucket_policy.main.policy
  sensitive   = true
}

output "access_configuration" {
  description = "Configuración de acceso al bucket"
  value = {
    vpc_endpoint_access = true
    cloudfront_access   = true
    public_access       = false
    encryption_enabled  = true
    versioning_enabled  = var.enable_versioning
  }
}

###################################################################
# URLs Y ENDPOINTS
###################################################################

output "bucket_website_endpoint" {
  description = "Endpoint del website del bucket (si está habilitado)"
  value       = "http://${aws_s3_bucket.main.bucket}.s3-website.${data.aws_region.current.name}.amazonaws.com"
}

output "bucket_s3_url" {
  description = "URL S3 del bucket"
  value       = "s3://${aws_s3_bucket.main.bucket}"
}

output "bucket_https_url" {
  description = "URL HTTPS del bucket"
  value       = "https://${aws_s3_bucket.main.bucket_domain_name}"
}

###################################################################
# INFORMACIÓN PARA INTEGRACIÓN
###################################################################

output "integration_info" {
  description = "Información para integración con otros servicios"
  value = {
    # Para CloudFront
    cloudfront_origin = {
      domain_name = aws_s3_bucket.main.bucket_regional_domain_name
      origin_id   = "${var.project_name}-${var.environment}-s3-origin"
      oac_id      = aws_cloudfront_origin_access_control.main.id
    }
    
    # Para EC2 access via VPC endpoint
    vpc_endpoint_access = {
      bucket_name     = aws_s3_bucket.main.bucket
      bucket_arn      = aws_s3_bucket.main.arn
      vpc_endpoint_id = var.s3_vpc_endpoint_id
      access_methods  = ["GetObject", "PutObject", "DeleteObject", "ListBucket"]
    }
    
    # Información general
    general = {
      bucket_name = aws_s3_bucket.main.bucket
      region      = data.aws_region.current.name
      environment = var.environment
      project     = var.project_name
    }
  }
}

###################################################################
# SAMPLE FILES (si están creados)
###################################################################

output "sample_files" {
  description = "Lista de archivos de ejemplo creados"
  value = var.create_sample_files ? {
    for k, v in aws_s3_object.sample_files : k => {
      key          = v.key
      etag         = v.etag
      content_type = v.content_type
      url          = "https://${aws_s3_bucket.main.bucket_domain_name}/${v.key}"
    }
  } : {}
}

###################################################################
# CONFIGURACIÓN COMPLETA
###################################################################

output "s3_configuration_summary" {
  description = "Resumen completo de la configuración de S3"
  value = {
    bucket = {
      name   = aws_s3_bucket.main.bucket
      arn    = aws_s3_bucket.main.arn
      region = data.aws_region.current.name
    }
    security = {
      encryption_enabled    = true
      versioning_enabled    = var.enable_versioning
      public_access_blocked = true
      cors_enabled         = var.enable_cors
    }
    access = {
      vpc_endpoint_enabled = true
      cloudfront_oac       = aws_cloudfront_origin_access_control.main.id
      lifecycle_policy     = var.enable_lifecycle_policy
    }
    integration = {
      vpc_endpoint_id      = var.s3_vpc_endpoint_id
      cloudfront_distribution = var.cloudfront_distribution_arn
      ec2_access_enabled  = var.ec2_instance_roles != null
    }
    deployment = {
      created_at  = timestamp()
      environment = var.environment
      project     = var.project_name
    }
  }
}
