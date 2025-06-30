###################################################################
# USER POOL OUTPUTS
###################################################################

output "user_pool_id" {
  description = "ID del User Pool de Cognito"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "ARN del User Pool de Cognito"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Endpoint del User Pool de Cognito"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_domain" {
  description = "Dominio del User Pool de Cognito"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "user_pool_hosted_ui_url" {
  description = "URL de la UI hospedada de Cognito"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

###################################################################
# USER POOL CLIENT OUTPUTS (API Gateway)
###################################################################

output "api_client_id" {
  description = "ID del cliente para API Gateway"
  value       = aws_cognito_user_pool_client.api_client.id
}

output "api_client_secret" {
  description = "Secret del cliente para API Gateway (si está habilitado)"
  value       = aws_cognito_user_pool_client.api_client.client_secret
  sensitive   = true
}

###################################################################
# WEB CLIENT OUTPUTS
###################################################################

output "web_client_id" {
  description = "ID del cliente web"
  value       = var.create_web_client ? aws_cognito_user_pool_client.web_client[0].id : null
}

output "web_client_secret" {
  description = "Secret del cliente web"
  value       = var.create_web_client ? aws_cognito_user_pool_client.web_client[0].client_secret : null
  sensitive   = true
}

###################################################################
# IDENTITY POOL OUTPUTS
###################################################################

output "identity_pool_id" {
  description = "ID del Identity Pool de Cognito"
  value       = var.create_identity_pool ? aws_cognito_identity_pool.main[0].id : null
}

output "authenticated_role_arn" {
  description = "ARN del rol para usuarios autenticados"
  value       = var.create_identity_pool ? aws_iam_role.authenticated[0].arn : null
}

output "unauthenticated_role_arn" {
  description = "ARN del rol para usuarios no autenticados"
  value       = var.create_identity_pool && var.allow_unauthenticated_identities ? aws_iam_role.unauthenticated[0].arn : null
}

###################################################################
# AUTHORIZER OUTPUTS PARA API GATEWAY
###################################################################

output "authorizer_invoke_arn" {
  description = "ARN para invocar el authorizer de Cognito en API Gateway"
  value       = aws_cognito_user_pool.main.arn
}

output "authorizer_audience" {
  description = "Audience para el authorizer (client ID)"
  value       = aws_cognito_user_pool_client.api_client.id
}

###################################################################
# INFORMACIÓN ÚTIL PARA CLIENTES
###################################################################

output "login_url" {
  description = "URL de login para la aplicación"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.api_client.id}&response_type=code&scope=email+openid+profile&redirect_uri=${length(var.callback_urls) > 0 ? var.callback_urls[0] : "http://localhost:3000/callback"}"
}

output "logout_url" {
  description = "URL de logout para la aplicación"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/logout?client_id=${aws_cognito_user_pool_client.api_client.id}&logout_uri=${length(var.logout_urls) > 0 ? var.logout_urls[0] : "http://localhost:3000/logout"}"
}

output "token_endpoint" {
  description = "Endpoint para obtener tokens"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/oauth2/token"
}

output "userinfo_endpoint" {
  description = "Endpoint para obtener información del usuario"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/oauth2/userInfo"
}

###################################################################
# DATA SOURCES
###################################################################

data "aws_region" "current" {}
