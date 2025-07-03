###################################################################
# S3 BUCKET FOR CLOUDFRONT LOGS (if not provided)
###################################################################

# S3 bucket for CloudFront logs
resource "aws_s3_bucket" "cloudfront_logs" {
  count    = var.log_bucket_domain_name == null ? 1 : 0
  provider = aws.us_east_1
  bucket   = "${var.project_name}-${var.environment}-cloudfront-logs-${random_string.log_bucket_suffix[0].result}"
  
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cloudfront-logs"
    Environment = var.environment
    Purpose     = "CloudFront Access Logs"
  })
}

# S3 bucket ACL for CloudFront logs (required for CloudFront logging)
resource "aws_s3_bucket_acl" "cloudfront_logs" {
  count      = var.log_bucket_domain_name == null ? 1 : 0
  provider   = aws.us_east_1
  bucket     = aws_s3_bucket.cloudfront_logs[0].id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logs]
}

# S3 bucket policy for CloudFront logs
resource "aws_s3_bucket_policy" "cloudfront_logs" {
  count    = var.log_bucket_domain_name == null ? 1 : 0
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.cloudfront_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudfront_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudfront_logs[0].arn
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.cloudfront_logs]
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# S3 bucket ownership controls for CloudFront logs
resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  count    = var.log_bucket_domain_name == null ? 1 : 0
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.cloudfront_logs[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Random suffix for log bucket
resource "random_string" "log_bucket_suffix" {
  count   = var.log_bucket_domain_name == null ? 1 : 0
  length  = 6
  special = false
  upper   = false
}

# S3 bucket public access block for CloudFront logs
resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  count    = var.log_bucket_domain_name == null ? 1 : 0
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.cloudfront_logs[0].id

  block_public_acls       = false  # Allow ACLs for CloudFront logging
  block_public_policy     = false  # Allow bucket policy for CloudFront logging
  ignore_public_acls      = false  # Allow ACLs for CloudFront logging
  restrict_public_buckets = false  # Allow CloudFront service access
}

###################################################################
# CLOUDFRONT DISTRIBUTION - CDN con múltiples orígenes (S3 + API Gateway)
###################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# Validación local del dominio
locals {
    # Extraer solo el dominio (primera parte antes de cualquier "/")
    api_domain_clean = split("/", var.api_gateway_domain_name)[0]
    
    # Determinar el origen principal
    primary_origin_id = var.primary_origin == "s3" ? "s3-${var.project_name}-${var.environment}" : "api-gateway-${var.project_name}-${var.environment}"
    
    # Cache behaviors predefinidos para S3 y API Gateway
    predefined_behaviors = var.s3_bucket_regional_domain_name != null && var.enable_dual_origin ? [
        {
            path_pattern           = "*.css"
            target_origin_id       = "s3-${var.project_name}-${var.environment}"
            viewer_protocol_policy = "redirect-to-https"
            allowed_methods        = ["GET", "HEAD", "OPTIONS"]
            cached_methods         = ["GET", "HEAD"]
            min_ttl               = 0
            default_ttl           = 86400      # 1 día para CSS
            max_ttl               = 31536000   # 1 año
            forward_query_string  = false
            forward_headers       = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
            forward_cookies       = "none"
            compress              = true
        },
        {
            path_pattern           = "*.js"
            target_origin_id       = "s3-${var.project_name}-${var.environment}"
            viewer_protocol_policy = "redirect-to-https"
            allowed_methods        = ["GET", "HEAD", "OPTIONS"]
            cached_methods         = ["GET", "HEAD"]
            min_ttl               = 0
            default_ttl           = 86400      # 1 día para JS
            max_ttl               = 31536000   # 1 año
            forward_query_string  = false
            forward_headers       = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
            forward_cookies       = "none"
            compress              = true
        },
        {
            path_pattern           = "*.html"
            target_origin_id       = "s3-${var.project_name}-${var.environment}"
            viewer_protocol_policy = "redirect-to-https"
            allowed_methods        = ["GET", "HEAD", "OPTIONS"]
            cached_methods         = ["GET", "HEAD"]
            min_ttl               = 0
            default_ttl           = 3600       # 1 hora para HTML
            max_ttl               = 86400      # 1 día
            forward_query_string  = false
            forward_headers       = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
            forward_cookies       = "none"
            compress              = true
        },
        {
            path_pattern           = "/api/*"
            target_origin_id       = "api-gateway-${var.project_name}-${var.environment}"
            viewer_protocol_policy = "redirect-to-https"
            allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
            cached_methods         = ["GET", "HEAD"]
            min_ttl               = 0
            default_ttl           = 0          # No cache para APIs
            max_ttl               = 86400
            forward_query_string  = true
            forward_headers       = ["*"]
            forward_cookies       = "all"
            compress              = true
        }
    ] : []
    
    # Combinar behaviors personalizados con predefinidos, evitando duplicados
    # Los behaviors personalizados tienen prioridad sobre los predefinidos
    predefined_paths = toset([for behavior in local.predefined_behaviors : behavior.path_pattern])
    custom_behaviors_filtered = [
        for behavior in var.cache_behaviors : {
            path_pattern           = behavior.path_pattern
            target_origin_id       = contains(["api-gateway", "api"], behavior.path_pattern) ? "api-gateway-${var.project_name}-${var.environment}" : local.primary_origin_id
            viewer_protocol_policy = behavior.viewer_protocol_policy
            allowed_methods        = behavior.allowed_methods
            cached_methods         = behavior.cached_methods
            min_ttl               = behavior.min_ttl
            default_ttl           = behavior.default_ttl
            max_ttl               = behavior.max_ttl
            forward_query_string  = behavior.forward_query_string
            forward_headers       = behavior.forward_headers
            forward_cookies       = behavior.forward_cookies
            compress              = behavior.compress
        }
        if !contains(local.predefined_paths, behavior.path_pattern)
    ]
    
    # Lista final de todos los cache behaviors
    all_cache_behaviors = concat(local.custom_behaviors_filtered, local.predefined_behaviors)
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
    provider = aws.us_east_1
    
    # Origen S3 (contenido estático)
    dynamic "origin" {
        for_each = var.s3_bucket_regional_domain_name != null ? [1] : []
        
        content {
            domain_name              = var.s3_bucket_regional_domain_name
            origin_id                = "s3-${var.project_name}-${var.environment}"
            origin_access_control_id = var.s3_origin_access_control_id
        }
    }
    
    # Origen API Gateway (contenido dinámico)
    origin {
        domain_name = local.api_domain_clean
        origin_id   = "api-gateway-${var.project_name}-${var.environment}"
        
        custom_origin_config {
            http_port              = 80
            https_port             = 443
            origin_protocol_policy = "https-only"  # Forzar HTTPS para cumplir CKV2_AWS_72
            origin_ssl_protocols   = ["TLSv1.2"]   # Solo TLS 1.2+ para cumplir CKV2_AWS_54
        }
        
        # Headers personalizados (opcional)
        dynamic "custom_header" {
            for_each = var.custom_headers
            content {
                name  = custom_header.value.name
                value = custom_header.value.value
            }
        }
    }

    # Configuración del cache behavior por defecto
    default_cache_behavior {
        target_origin_id       = local.primary_origin_id
        viewer_protocol_policy = "redirect-to-https"  # Forzar HTTPS para cumplir CKV_AWS_34
        
        # Métodos HTTP permitidos
        allowed_methods  = var.allowed_methods
        cached_methods   = var.cached_methods
        
        # Configuración de TTL
        min_ttl     = var.cache_min_ttl
        default_ttl = var.cache_default_ttl
        max_ttl     = var.cache_max_ttl
        
        # Configuración de cookies y query strings
        forwarded_values {
            query_string = var.forward_query_string
            headers      = var.forward_headers
            
            cookies {
                forward = var.forward_cookies
            }
        }
        
        # Compresión
        compress = var.enable_compression
        
        # Configuración de funciones (opcional)
        dynamic "function_association" {
            for_each = var.edge_functions
            content {
                event_type   = function_association.value.event_type
                function_arn = function_association.value.function_arn
            }
        }
    }

    # Cache behaviors para rutas específicas (combinados)
    dynamic "ordered_cache_behavior" {
        for_each = local.all_cache_behaviors
        content {
            path_pattern           = ordered_cache_behavior.value.path_pattern
            target_origin_id       = ordered_cache_behavior.value.target_origin_id
            viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy
            
            allowed_methods = ordered_cache_behavior.value.allowed_methods
            cached_methods  = ordered_cache_behavior.value.cached_methods
            
            min_ttl     = ordered_cache_behavior.value.min_ttl
            default_ttl = ordered_cache_behavior.value.default_ttl
            max_ttl     = ordered_cache_behavior.value.max_ttl
            
            forwarded_values {
                query_string = ordered_cache_behavior.value.forward_query_string
                headers      = ordered_cache_behavior.value.forward_headers
                
                cookies {
                    forward = ordered_cache_behavior.value.forward_cookies
                }
            }
            
            compress = ordered_cache_behavior.value.compress
        }
    }

    # Restricciones geográficas
    restrictions {
        geo_restriction {
            restriction_type = var.geo_restriction_type
            locations        = var.geo_restriction_locations
        }
    }

    # Configuración de certificado SSL
    viewer_certificate {
        # Para dominio personalizado
        acm_certificate_arn      = var.ssl_certificate_arn
        ssl_support_method       = var.ssl_certificate_arn != null ? "sni-only" : null
        minimum_protocol_version = var.ssl_certificate_arn != null ? "TLSv1.2_2021" : "TLSv1.2_2021"  # Asegurar TLS 1.2+ para cumplir CKV_AWS_174
        
        # Para dominio por defecto de CloudFront
        cloudfront_default_certificate = var.ssl_certificate_arn == null ? true : null
    }

    # Configuración general
    enabled             = true
    is_ipv6_enabled     = var.enable_ipv6
    default_root_object = var.default_root_object != null ? var.default_root_object : "index.html"  # Asegurar default root object para cumplir CKV_AWS_305
    comment             = "CloudFront distribution for ${var.project_name} (${var.enable_dual_origin ? "S3+API Gateway" : var.primary_origin}) in ${var.environment}"
    
    # Aliases (dominios personalizados)
    aliases = var.domain_aliases

    # Configuración de precios
    price_class = var.price_class

    # Configuración de WAF (obligatoria para cumplir CKV_AWS_68)
    web_acl_id = var.web_acl_arn  # Force WAF attachment

    # Configuración de logging (obligatoria para cumplir CKV_AWS_86)
    logging_config {
        include_cookies = false
        bucket         = var.log_bucket_domain_name != null ? var.log_bucket_domain_name : aws_s3_bucket.cloudfront_logs[0].bucket_domain_name
        prefix         = var.log_prefix != null ? var.log_prefix : "cloudfront-logs/"
    }

    # Configuración de páginas de error personalizadas
    dynamic "custom_error_response" {
        for_each = var.custom_error_responses
        content {
            error_code            = custom_error_response.value.error_code
            response_code         = custom_error_response.value.response_code
            response_page_path    = custom_error_response.value.response_page_path
            error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
        }
    }

    # Tags
    tags = merge(var.tags, {
        Name        = "${var.project_name}-${var.environment}-cloudfront"
        Environment = var.environment
        Type        = "CloudFront"
        Origin      = var.enable_dual_origin ? "S3 + API Gateway" : (var.primary_origin == "s3" ? "S3" : "API Gateway")
        PrimaryOrigin = var.primary_origin
    })

    # Esperar a que el certificado esté validado
    depends_on = [var.ssl_certificate_arn]
}

# CloudFront Function para manipulación de headers (opcional)
resource "aws_cloudfront_function" "request_headers" {
    provider = aws.us_east_1
    count   = var.create_edge_function ? 1 : 0
    name    = "${var.project_name}-${var.environment}-request-headers"
    runtime = "cloudfront-js-1.0"
    comment = "Function to add custom headers to requests"
    publish = true
    
    code = var.edge_function_code != null ? var.edge_function_code : <<-EOT
function handler(event) {
    var request = event.request;
    
    // Agregar headers personalizados
    request.headers['x-forwarded-by'] = {value: 'cloudfront'};
    request.headers['x-environment'] = {value: '${var.environment}'};
    request.headers['x-project'] = {value: '${var.project_name}'};
    
    return request;
}
EOT
}

# CloudWatch Alarms para monitoreo
resource "aws_cloudwatch_metric_alarm" "origin_latency" {
    provider = aws.us_east_1
    count = var.enable_monitoring ? 1 : 0
    
    alarm_name          = "${var.project_name}-${var.environment}-cloudfront-origin-latency"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = "2"
    metric_name         = "OriginLatency"
    namespace           = "AWS/CloudFront"
    period              = "300"
    statistic           = "Average"
    threshold           = var.origin_latency_threshold
    alarm_description   = "This metric monitors CloudFront origin latency"
    alarm_actions       = var.alarm_topic_arn != null ? [var.alarm_topic_arn] : []
    actions_enabled     = true  # Fix CKV_AWS_319

    dimensions = {
        DistributionId = aws_cloudfront_distribution.main.id
    }

    tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "error_rate" {
    provider = aws.us_east_1
    count = var.enable_monitoring ? 1 : 0
    
    alarm_name          = "${var.project_name}-${var.environment}-cloudfront-error-rate"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = "2"
    metric_name         = "4xxErrorRate"
    namespace           = "AWS/CloudFront"
    period              = "300"
    statistic           = "Average"
    threshold           = var.error_rate_threshold
    alarm_description   = "This metric monitors CloudFront 4xx error rate"
    alarm_actions       = var.alarm_topic_arn != null ? [var.alarm_topic_arn] : []
    actions_enabled     = true  # Fix CKV_AWS_319

    dimensions = {
        DistributionId = aws_cloudfront_distribution.main.id
    }

    tags = var.tags
}
