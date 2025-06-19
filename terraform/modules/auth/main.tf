# Módulo de autenticación - Recursos de Cognito y API Gateway

# Crear el User Pool de Cognito para la autenticación de clientes
resource "aws_cognito_user_pool" "clientes" {
  name = "${var.project_name}-clientes-user-pool"

  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }
}

# Crear el User Pool Client para clientes
resource "aws_cognito_user_pool_client" "clientes" {
  name                 = "${var.project_name}-clientes-app-client"
  user_pool_id         = aws_cognito_user_pool.clientes.id
  generate_secret      = false
  explicit_auth_flows  = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}

# Crear el Identity Pool para los clientes
resource "aws_cognito_identity_pool" "clientes" {
  identity_pool_name               = "${var.project_name}-clientes-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.clientes.id
    provider_name           = aws_cognito_user_pool.clientes.endpoint
  }
}

# Crear el User Pool de Cognito para administradores
resource "aws_cognito_user_pool" "administradores" {
  name = "${var.project_name}-admin-user-pool"

  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length    = 10
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }
}

# Crear el User Pool Client para administradores
resource "aws_cognito_user_pool_client" "administradores" {
  name                 = "${var.project_name}-admin-app-client"
  user_pool_id         = aws_cognito_user_pool.administradores.id
  explicit_auth_flows  = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  generate_secret      = false
}

# Crear el Identity Pool para administradores
resource "aws_cognito_identity_pool" "administradores" {
  identity_pool_name               = "${var.project_name}-admin-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.administradores.id
    provider_name           = aws_cognito_user_pool.administradores.endpoint
    server_side_token_check = false
  }
}

# Crear el dominio para clientes en Cognito
resource "aws_cognito_user_pool_domain" "clientes" {
  domain       = "${var.project_name}-clientes-domain"
  user_pool_id = aws_cognito_user_pool.clientes.id
}

# Crear el dominio para administradores en Cognito
resource "aws_cognito_user_pool_domain" "administradores" {
  domain       = "${var.project_name}-admin-domain"
  user_pool_id = aws_cognito_user_pool.administradores.id
}

# Crear API Gateway para la API de autenticación (DEBE ESTAR ANTES DEL AUTHORIZER)
resource "aws_api_gateway_rest_api" "villa_alfredo_api" {
  name        = "${var.project_name}-api"
  description = "API de autenticación y gestión de usuarios"
}

# Crear el Authorizer de Cognito CORREGIDO
resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name          = "${var.project_name}-Cognito-Auth"
  rest_api_id   = aws_api_gateway_rest_api.villa_alfredo_api.id
  type          = "COGNITO_USER_POOLS"  # Tipo corregido
  provider_arns = [aws_cognito_user_pool.clientes.arn]  # Solo necesita el ARN del User Pool
}

# Crear el recurso /auth en la API
resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.villa_alfredo_api.id
  parent_id   = aws_api_gateway_rest_api.villa_alfredo_api.root_resource_id
  path_part   = "auth"
}

# Crear el método GET para el recurso /auth con autorización Cognito
resource "aws_api_gateway_method" "auth_get" {
  rest_api_id   = aws_api_gateway_rest_api.villa_alfredo_api.id
  resource_id   = aws_api_gateway_resource.auth.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id  # Referencia directa al autorizador
}