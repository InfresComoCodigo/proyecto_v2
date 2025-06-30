###################################################################
# OUTPUTS - WAF Module
###################################################################

# WAF Web ACL
output "web_acl_id" {
  description = "ID del WAF Web ACL"
  value       = aws_wafv2_web_acl.cloudfront_waf.id
}

output "web_acl_arn" {
  description = "ARN del WAF Web ACL"
  value       = aws_wafv2_web_acl.cloudfront_waf.arn
}

output "web_acl_name" {
  description = "Nombre del WAF Web ACL"
  value       = aws_wafv2_web_acl.cloudfront_waf.name
}

output "web_acl_capacity" {
  description = "Capacidad utilizada por el WAF Web ACL"
  value       = aws_wafv2_web_acl.cloudfront_waf.capacity
}

# WAF Web ACL con Whitelist (si está habilitado)
output "web_acl_whitelist_id" {
  description = "ID del WAF Web ACL con whitelist (si está habilitado)"
  value       = length(aws_wafv2_web_acl.cloudfront_waf_with_whitelist) > 0 ? aws_wafv2_web_acl.cloudfront_waf_with_whitelist[0].id : null
}

output "web_acl_whitelist_arn" {
  description = "ARN del WAF Web ACL con whitelist (si está habilitado)"
  value       = length(aws_wafv2_web_acl.cloudfront_waf_with_whitelist) > 0 ? aws_wafv2_web_acl.cloudfront_waf_with_whitelist[0].arn : null
}

# IP Sets
output "blocked_ip_set_id" {
  description = "ID del IP Set de direcciones bloqueadas"
  value       = length(aws_wafv2_ip_set.blocked_ips) > 0 ? aws_wafv2_ip_set.blocked_ips[0].id : null
}

output "blocked_ip_set_arn" {
  description = "ARN del IP Set de direcciones bloqueadas"
  value       = length(aws_wafv2_ip_set.blocked_ips) > 0 ? aws_wafv2_ip_set.blocked_ips[0].arn : null
}

output "allowed_ip_set_id" {
  description = "ID del IP Set de direcciones permitidas"
  value       = length(aws_wafv2_ip_set.allowed_ips) > 0 ? aws_wafv2_ip_set.allowed_ips[0].id : null
}

output "allowed_ip_set_arn" {
  description = "ARN del IP Set de direcciones permitidas"
  value       = length(aws_wafv2_ip_set.allowed_ips) > 0 ? aws_wafv2_ip_set.allowed_ips[0].arn : null
}

# CloudWatch Log Group
output "log_group_name" {
  description = "Nombre del CloudWatch Log Group para WAF (si está habilitado)"
  value       = length(aws_cloudwatch_log_group.waf_log_group) > 0 ? aws_cloudwatch_log_group.waf_log_group[0].name : null
}

output "log_group_arn" {
  description = "ARN del CloudWatch Log Group para WAF (si está habilitado)"
  value       = length(aws_cloudwatch_log_group.waf_log_group) > 0 ? aws_cloudwatch_log_group.waf_log_group[0].arn : null
}

# Información de configuración
output "waf_configuration" {
  description = "Resumen de la configuración del WAF"
  value = {
    name                          = aws_wafv2_web_acl.cloudfront_waf.name
    scope                        = "CLOUDFRONT"
    sql_injection_protection     = var.enable_sql_injection_protection
    rate_limiting_enabled        = var.enable_rate_limiting
    rate_limit_requests          = var.rate_limit_requests
    blocked_countries_count      = length(var.blocked_countries)
    allowed_countries_count      = length(var.allowed_countries)
    blocked_ip_addresses_count   = length(var.blocked_ip_addresses)
    allowed_ip_addresses_count   = length(var.allowed_ip_addresses)
    blocked_user_agents_count    = length(var.blocked_user_agents)
    cloudwatch_metrics_enabled  = var.enable_cloudwatch_metrics
    waf_logging_enabled          = var.enable_waf_logging
  }
}

# Para usar en CloudFront
output "cloudfront_web_acl_arn" {
  description = "ARN del WAF Web ACL para usar en CloudFront (usa whitelist si está disponible, sino el normal)"
  value       = length(var.allowed_ip_addresses) > 0 ? aws_wafv2_web_acl.cloudfront_waf_with_whitelist[0].arn : aws_wafv2_web_acl.cloudfront_waf.arn
}
