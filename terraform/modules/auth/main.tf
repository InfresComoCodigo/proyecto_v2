resource "aws_cognito_user_pool" "clientes" {
  name = "clientes-user-pool"
  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    name = "email"
    required = true
    mutable = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  password_policy {
    minimum_length = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers = true
    require_symbols = false
  }
}

resource "aws_cognito_user_pool" "administradores" {
  name = "admin-user-pool"
  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    name = "email"
    required = true
    mutable = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length = 10
    require_lowercase = true
    require_uppercase = true
    require_numbers = true
    require_symbols = true
  }
}

resource "aws_cognito_user_pool_domain" "clientes" {
  domain       = "${var.project_name}-clientes-domain"
  user_pool_id = aws_cognito_user_pool.clientes.id
}

resource "aws_cognito_user_pool_domain" "administradores" {
  domain       = "${var.project_name}-admin-domain"
  user_pool_id = aws_cognito_user_pool.administradores.id
}

resource "aws_cognito_identity_pool" "clientes" {
  identity_pool_name               = "${var.project_name}-clientes-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id         = aws_cognito_user_pool_client.clientes.id
    provider_name     = aws_cognito_user_pool.clientes.endpoint
    server_side_token_check = false
  }
}

resource "aws_cognito_identity_pool" "administradores" {
  identity_pool_name               = "${var.project_name}-admin-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id         = aws_cognito_user_pool_client.administradores.id
    provider_name     = aws_cognito_user_pool.administradores.endpoint
    server_side_token_check = false
  }
}

resource "aws_cognito_user_pool_client" "clientes" {
  name         = "${var.project_name}-clientes-app-client"
  user_pool_id = aws_cognito_user_pool.clientes.id
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  generate_secret     = false
}

resource "aws_cognito_user_pool_client" "administradores" {
  name         = "${var.project_name}-admin-app-client"
  user_pool_id = aws_cognito_user_pool.administradores.id
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  generate_secret     = false
}