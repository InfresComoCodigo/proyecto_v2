###################################################################
# OUTPUTS - CDN Module
###################################################################

output "cloudfront_distribution_id" {
  description = "ID de la distribución de CloudFront"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_distribution_arn" {
  description = "ARN de la distribución de CloudFront"
  value       = aws_cloudfront_distribution.main.arn
}

output "cloudfront_domain_name" {
  description = "Nombre de dominio de la distribución de CloudFront"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "Hosted Zone ID de CloudFront (para Route 53)"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "cloudfront_url" {
  description = "URL completa de CloudFront"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "cloudfront_status" {
  description = "Estado de la distribución de CloudFront"
  value       = aws_cloudfront_distribution.main.status
}

output "cloudfront_etag" {
  description = "ETag de la distribución (para actualizaciones)"
  value       = aws_cloudfront_distribution.main.etag
}

# Información del origen
output "origin_info" {
  description = "Información del origen configurado"
  value = {
    domain_name = var.api_gateway_domain_name
    origin_id   = "api-gateway-${var.project_name}-${var.environment}"
    protocol    = "https-only"
  }
}

# Información de cache
output "cache_configuration" {
  description = "Configuración de cache aplicada"
  value = {
    min_ttl     = var.cache_min_ttl
    default_ttl = var.cache_default_ttl
    max_ttl     = var.cache_max_ttl
    behaviors   = length(var.cache_behaviors)
  }
}

# Información de funciones Edge (si existen)
output "edge_function_arn" {
  description = "ARN de la función Edge creada"
  value       = var.create_edge_function ? aws_cloudfront_function.request_headers[0].arn : null
}

output "edge_function_etag" {
  description = "ETag de la función Edge"
  value       = var.create_edge_function ? aws_cloudfront_function.request_headers[0].etag : null
}

# Información de monitoreo
output "monitoring_alarms" {
  description = "ARNs de las alarmas de CloudWatch creadas"
  value = var.enable_monitoring ? {
    origin_latency = aws_cloudwatch_metric_alarm.origin_latency[0].arn
    error_rate     = aws_cloudwatch_metric_alarm.error_rate[0].arn
  } : null
}

# Información de WAF
output "waf_configuration" {
  description = "Configuración de WAF aplicada"
  value = {
    enabled    = var.enable_waf
    web_acl_id = var.web_acl_id
    associated = var.enable_waf && var.web_acl_id != null
  }
}

# Información completa para integration
output "distribution_info" {
  description = "Información completa de la distribución de CloudFront"
  value = {
    id              = aws_cloudfront_distribution.main.id
    arn             = aws_cloudfront_distribution.main.arn
    domain_name     = aws_cloudfront_distribution.main.domain_name
    hosted_zone_id  = aws_cloudfront_distribution.main.hosted_zone_id
    url             = "https://${aws_cloudfront_distribution.main.domain_name}"
    status          = aws_cloudfront_distribution.main.status
    etag            = aws_cloudfront_distribution.main.etag
    price_class     = var.price_class
    aliases         = var.domain_aliases
    origin_domain   = var.api_gateway_domain_name
    viewer_protocol = var.viewer_protocol_policy
    compression     = var.enable_compression
    ipv6_enabled    = var.enable_ipv6
    geo_restrictions = {
      type      = var.geo_restriction_type
      locations = var.geo_restriction_locations
    }
  }
}
