terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

###################################################################
# AWS WAF v2 PARA CLOUDFRONT
###################################################################

# NOTE: WAF para CloudFront debe estar en us-east-1
# Configurar provider para us-east-1 si no está ya configurado

# Random suffix for unique resource naming
resource "random_string" "waf_suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  common_tags = merge(var.tags, {
    Module      = "WAF"
    Environment = var.environment
    Project     = var.project_name
  })
}

###################################################################
# WAF WEB ACL PARA CLOUDFRONT
###################################################################
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  provider = aws.us_east_1

  lifecycle {
    ignore_changes = [
      rule,
    ]
  }

  name  = "${var.project_name}-${var.environment}-cloudfront-waf-${random_string.waf_suffix.result}"
  description = "WAF para proteger CloudFront Distribution de ${var.project_name}"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Regla 1: Protección contra ataques comunes (Core Rule Set)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Regla 2: Protección contra ataques conocidos de aplicaciones web
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Regla 3: Protección contra SQL Injection (static rule)
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLiRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Regla 4: Rate Limiting (simplified)
  rule {
    name     = "RateLimitRule"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit_requests
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  # Configuración de visibilidad
  visibility_config {
    cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
    metric_name                = "${var.project_name}${var.environment}CloudFrontWAF"
    sampled_requests_enabled   = var.enable_sampled_requests
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cloudfront-waf"
    Type = "WAF-CloudFront"
  })
}

###################################################################
# IP SET PARA DIRECCIONES IP BLOQUEADAS
###################################################################
resource "aws_wafv2_ip_set" "blocked_ips" {
  provider = aws.us_east_1
  count = length(var.blocked_ip_addresses) > 0 ? 1 : 0

  name               = "${var.project_name}-${var.environment}-blocked-ips"
  description        = "IP addresses blocked for ${var.project_name}"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"

  addresses = var.blocked_ip_addresses

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-blocked-ips"
    Type = "WAF-IPSet"
  })
}

###################################################################
# IP SET PARA DIRECCIONES IP PERMITIDAS (WHITELIST)
###################################################################
resource "aws_wafv2_ip_set" "allowed_ips" {
  provider = aws.us_east_1
  count = length(var.allowed_ip_addresses) > 0 ? 1 : 0

  name               = "${var.project_name}-${var.environment}-allowed-ips"
  description        = "IP addresses allowed for ${var.project_name}"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"

  addresses = var.allowed_ip_addresses

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-allowed-ips"
    Type = "WAF-IPSet"
  })
}

###################################################################
# REGLA ADICIONAL PARA IP WHITELIST
###################################################################
resource "aws_wafv2_web_acl" "cloudfront_waf_with_whitelist" {
  provider = aws.us_east_1
  count = length(var.allowed_ip_addresses) > 0 ? 1 : 0

  name        = "${var.project_name}-${var.environment}-cloudfront-waf-whitelist-${random_string.waf_suffix.result}"
  description = "WAF con whitelist de IPs para ${var.project_name}"
  scope       = "CLOUDFRONT"

  default_action {
    block {}
  }

  # Regla de whitelist (prioridad más alta)
  rule {
    name     = "IPWhitelistRule"
    priority = 0

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed_ips[0].arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IPWhitelistRuleMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.enable_cloudwatch_metrics
    metric_name                = "${var.project_name}${var.environment}CloudFrontWAFWhitelist"
    sampled_requests_enabled   = var.enable_sampled_requests
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cloudfront-waf-whitelist"
    Type = "WAF-CloudFront-Whitelist"
  })
}

###################################################################
# CLOUDWATCH LOG GROUP PARA WAF LOGS
###################################################################
resource "aws_cloudwatch_log_group" "waf_log_group" {
  provider = aws.us_east_1
  count = var.enable_waf_logging ? 1 : 0

  name              = "/aws/waf/${var.project_name}-${var.environment}-cloudfront"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-waf-logs"
    Type = "CloudWatch-LogGroup"
  })
}

###################################################################
# CONFIGURACIÓN DE LOGGING PARA WAF
###################################################################
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  provider = aws.us_east_1
  count = var.enable_waf_logging ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.cloudfront_waf.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_log_group[0].arn]

  # Filtros de logging (opcional)
  dynamic "redacted_fields" {
    for_each = var.redacted_fields
    content {
      dynamic "single_header" {
        for_each = redacted_fields.value.type == "single_header" ? [redacted_fields.value.name] : []
        content {
          name = single_header.value
        }
      }
      dynamic "uri_path" {
        for_each = redacted_fields.value.type == "uri_path" ? [1] : []
        content {}
      }
      dynamic "query_string" {
        for_each = redacted_fields.value.type == "query_string" ? [1] : []
        content {}
      }
    }
  }
}
