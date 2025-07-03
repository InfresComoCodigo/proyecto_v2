# Random string to ensure unique resource names
resource "random_string" "api_suffix" {
  length  = 6
  special = false
  upper   = false
}

###################################################################
# API GATEWAY - REST API con integración directa a ALB público
###################################################################

# CloudWatch Log Group para API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}-${random_string.api_suffix.result}"
  retention_in_days = 365            # Retención mínima de 1 año para cumplir CKV_AWS_338
  kms_key_id        = var.kms_key_id # Cifrado con KMS para cumplir CKV_AWS_158

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-api-gateway-logs"
  })
}

# Data source para obtener información del ALB
# Note: ALB name is dynamic with random suffix, use provided DNS name instead
# data "aws_lb" "alb" {
#     name = "${var.project_name}-${var.environment}-alb"
# }

# REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-${var.environment}-api"
  description = "API Gateway para ${var.project_name} en ambiente ${var.environment}"

  endpoint_configuration {
    types = [var.api_gateway_type]
  }

  # Política de recursos (opcional)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "execute-api:Invoke"
        Resource  = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-api-gateway"
  })
}

# Recurso raíz proxy (captura todas las rutas)
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# Método ANY para el recurso proxy (acepta todos los métodos HTTP)
resource "aws_api_gateway_method" "proxy" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.proxy.id
  http_method      = "ANY"
  authorization    = "AWS_IAM" # Force IAM authorization to fix CKV2_AWS_70 and CKV_AWS_59
  api_key_required = true      # Require API key for additional security

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

# Integración del método con el ALB directamente (sin VPC Link)
resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${var.alb_dns_name}/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  timeout_milliseconds = 29000
}

# Método para el recurso raíz (/)
resource "aws_api_gateway_method" "root" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_rest_api.main.root_resource_id
  http_method      = "ANY"
  authorization    = "AWS_IAM" # Force IAM authorization to fix CKV2_AWS_70 and CKV_AWS_59
  api_key_required = true      # Require API key for additional security
}

# Integración para el recurso raíz
resource "aws_api_gateway_integration" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root.http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${var.alb_dns_name}/"

  timeout_milliseconds = 29000
}

# Deployment del API
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_integration.proxy.id,
      aws_api_gateway_method.root.id,
      aws_api_gateway_integration.root.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true # Fix CKV_AWS_217
  }

  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.proxy,
    aws_api_gateway_method.root,
    aws_api_gateway_integration.root,
  ]
}

# Stage del API
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.stage_name

  # Configuración de throttling se maneja en method_settings

  # Configuración de logging
  dynamic "access_log_settings" {
    for_each = var.enable_logging ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
      format = jsonencode({
        requestId      = "$context.requestId"
        ip             = "$context.identity.sourceIp"
        caller         = "$context.identity.caller"
        user           = "$context.identity.user"
        requestTime    = "$context.requestTime"
        httpMethod     = "$context.httpMethod"
        resourcePath   = "$context.resourcePath"
        status         = "$context.status"
        protocol       = "$context.protocol"
        responseLength = "$context.responseLength"
        responseTime   = "$context.responseTime"
        error          = "$context.error.message"
        errorType      = "$context.error.messageString"
      })
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-api-stage"
  })

  depends_on = [aws_cloudwatch_log_group.api_gateway_logs]
}

# Configuración de método settings para logging
resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = var.log_level
    data_trace_enabled     = true
    throttling_rate_limit  = var.throttle_rate_limit
    throttling_burst_limit = var.throttle_burst_limit
    caching_enabled        = true
    cache_ttl_in_seconds   = 300
    cache_data_encrypted   = true # Cifrado de cache para cumplir CKV_AWS_308
  }

  depends_on = [aws_api_gateway_account.main]
}

###################################################################
# COGNITO AUTHORIZER
###################################################################

resource "aws_api_gateway_authorizer" "cognito" {
  count         = var.enable_cognito_auth ? 1 : 0
  name          = "${var.project_name}-${var.environment}-cognito-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.main.id
  provider_arns = [var.cognito_user_pool_arn]

  # Configuración adicional del authorizer
  identity_source                  = "method.request.header.Authorization"
  authorizer_result_ttl_in_seconds = var.authorizer_ttl

  depends_on = [aws_api_gateway_rest_api.main]
}

###################################################################
# MÉTODO PÚBLICO (SIN AUTENTICACIÓN) - OPCIONAL
###################################################################

# Recurso para endpoints públicos (ej: /public/*)
resource "aws_api_gateway_resource" "public" {
  count       = var.create_public_endpoints ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "public"
}

resource "aws_api_gateway_resource" "public_proxy" {
  count       = var.create_public_endpoints ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.public[0].id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "public_proxy" {
  count            = var.create_public_endpoints ? 1 : 0
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.public_proxy[0].id
  http_method      = "ANY"
  authorization    = "AWS_IAM" # Fix CKV2_AWS_70 - require authorization
  api_key_required = true      # Require API key for security

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "public_proxy" {
  count       = var.create_public_endpoints ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.public_proxy[0].id
  http_method = aws_api_gateway_method.public_proxy[0].http_method

  type                    = "HTTP_PROXY"
  integration_http_method = "ANY"
  uri                     = "http://${var.alb_dns_name}/public/{proxy}"

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  timeout_milliseconds = 29000
}

# Dominio personalizado (opcional - comentado por defecto)
# Descomenta estas líneas si tienes un dominio y certificado SSL

# resource "aws_api_gateway_domain_name" "main" {
#     domain_name     = "api.yourdomain.com"
#     certificate_arn = "arn:aws:acm:us-east-1:account:certificate/certificate-id"
#     
#     endpoint_configuration {
#         types = [var.api_gateway_type]
#     }
#     
#     tags = merge(var.tags, {
#         Name = "${var.project_name}-${var.environment}-api-domain"
#     })
# }

# resource "aws_api_gateway_base_path_mapping" "main" {
#     api_id      = aws_api_gateway_rest_api.main.id
#     stage_name  = aws_api_gateway_stage.main.stage_name
#     domain_name = aws_api_gateway_domain_name.main.domain_name
# }

# IAM Role for API Gateway CloudWatch Logging
resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.project_name}-${var.environment}-api-gateway-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-api-gateway-cloudwatch-role"
  })
}

# IAM Role Policy Attachment for API Gateway CloudWatch
resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# API Gateway Account Settings
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}
