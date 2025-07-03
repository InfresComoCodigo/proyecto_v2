###################################################################
# RANDOM SUFFIX FOR UNIQUE NAMING
###################################################################

resource "random_string" "cognito_suffix" {
  length  = 6
  special = false
  upper   = false
}

###################################################################
# COGNITO USER POOL
###################################################################

resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-${var.environment}-userpool-${random_string.cognito_suffix.result}"

  # Configuración de contraseñas
  password_policy {
    minimum_length    = var.password_minimum_length
    require_lowercase = var.password_require_lowercase
    require_numbers   = var.password_require_numbers
    require_symbols   = var.password_require_symbols
    require_uppercase = var.password_require_uppercase
  }

  # Configuración de usuario
  username_configuration {
    case_sensitive = false
  }

  # Atributos requeridos
  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Configuración de email
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Verificación automática
  auto_verified_attributes = ["email"]

  # Configuración de MFA (opcional)
  mfa_configuration = var.enable_mfa ? "ON" : "OFF"

  # Configuración de recuperación de cuenta
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Configuración de dispositivos
  device_configuration {
    challenge_required_on_new_device      = var.challenge_required_on_new_device
    device_only_remembered_on_user_prompt = var.device_only_remembered_on_user_prompt
  }

  # Configuración de lambda triggers (opcional)
  dynamic "lambda_config" {
    for_each = var.enable_lambda_triggers ? [1] : []
    content {
      pre_sign_up    = var.pre_sign_up_lambda_arn
      post_confirmation = var.post_confirmation_lambda_arn
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cognito-userpool"
    Environment = var.environment
  })
}

###################################################################
# COGNITO USER POOL DOMAIN
###################################################################

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-${var.environment}-auth-${random_string.cognito_suffix.result}"
  user_pool_id = aws_cognito_user_pool.main.id
}

###################################################################
# COGNITO USER POOL CLIENT (para API Gateway)
###################################################################

resource "aws_cognito_user_pool_client" "api_client" {
  name         = "${var.project_name}-${var.environment}-api-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # Configuración de tokens
  access_token_validity                = var.access_token_validity
  id_token_validity                   = var.id_token_validity
  refresh_token_validity              = var.refresh_token_validity
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # Configuración de autenticación
  generate_secret                      = false
  prevent_user_existence_errors       = "ENABLED"
  enable_token_revocation             = true
  enable_propagate_additional_user_context_data = false

  # Flujos de autenticación permitidos
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  # URLs de callback y logout (para aplicaciones web)
  callback_urls = length(var.callback_urls) > 0 ? var.callback_urls : null
  logout_urls   = length(var.logout_urls) > 0 ? var.logout_urls : null

  # Scopes OAuth2 - Solo configurar si hay flows OAuth
  allowed_oauth_flows                  = length(var.allowed_oauth_flows) > 0 ? var.allowed_oauth_flows : null
  allowed_oauth_flows_user_pool_client = length(var.allowed_oauth_flows) > 0
  allowed_oauth_scopes                 = length(var.allowed_oauth_flows) > 0 ? var.allowed_oauth_scopes : null
  supported_identity_providers         = length(var.allowed_oauth_flows) > 0 ? var.supported_identity_providers : null

  # Configuración de lectura/escritura de atributos
  read_attributes  = var.read_attributes
  write_attributes = var.write_attributes
}

###################################################################
# COGNITO USER POOL CLIENT (para aplicaciones web/móviles)
###################################################################

resource "aws_cognito_user_pool_client" "web_client" {
  count        = var.create_web_client ? 1 : 0
  name         = "${var.project_name}-${var.environment}-web-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # Configuración de tokens
  access_token_validity                = var.access_token_validity
  id_token_validity                   = var.id_token_validity
  refresh_token_validity              = var.refresh_token_validity
  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # Configuración de autenticación
  generate_secret                      = true
  prevent_user_existence_errors       = "ENABLED"
  enable_token_revocation             = true

  # Flujos de autenticación permitidos
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"
  ]

  # URLs de callback y logout
  callback_urls = var.web_callback_urls
  logout_urls   = var.web_logout_urls

  # Scopes OAuth2
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]

  # Configuración de lectura/escritura de atributos
  read_attributes  = ["email", "email_verified"]
  write_attributes = ["email"]
}

###################################################################
# COGNITO IDENTITY POOL (opcional para acceso a recursos AWS)
###################################################################

resource "aws_cognito_identity_pool" "main" {
  count                            = var.create_identity_pool ? 1 : 0
  identity_pool_name               = "${var.project_name}-${var.environment}-identity-pool"
  allow_unauthenticated_identities = var.allow_unauthenticated_identities

  cognito_identity_providers {
    client_id     = aws_cognito_user_pool_client.api_client.id
    provider_name = aws_cognito_user_pool.main.endpoint
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cognito-identity-pool"
    Environment = var.environment
  })
}

###################################################################
# IAM ROLES PARA IDENTITY POOL
###################################################################

# Rol para usuarios autenticados
resource "aws_iam_role" "authenticated" {
  count = var.create_identity_pool ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cognito-authenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main[0].id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cognito-authenticated-role"
    Environment = var.environment
  })
}

# Política para usuarios autenticados
resource "aws_iam_role_policy" "authenticated" {
  count = var.create_identity_pool ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cognito-authenticated-policy"
  role  = aws_iam_role.authenticated[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-sync:*",
          "cognito-identity:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Rol para usuarios no autenticados (si está habilitado)
resource "aws_iam_role" "unauthenticated" {
  count = var.create_identity_pool && var.allow_unauthenticated_identities ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cognito-unauthenticated-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main[0].id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "unauthenticated"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-cognito-unauthenticated-role"
    Environment = var.environment
  })
}

# Asociación de roles con identity pool
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  count            = var.create_identity_pool ? 1 : 0
  identity_pool_id = aws_cognito_identity_pool.main[0].id

  roles = {
    authenticated = aws_iam_role.authenticated[0].arn
    unauthenticated = var.allow_unauthenticated_identities ? aws_iam_role.unauthenticated[0].arn : null
  }
}
