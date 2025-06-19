output "clientes_user_pool_id" {
  value = aws_cognito_user_pool.clientes.id
}

output "admin_user_pool_id" {
  value = aws_cognito_user_pool.administradores.id
}

output "clientes_user_pool_arn" {
  value = aws_cognito_user_pool.clientes.arn
}

output "admin_user_pool_arn" {
  value = aws_cognito_user_pool.administradores.arn
}

output "clientes_identity_pool_id" {
  value = aws_cognito_identity_pool.clientes.id
}

output "admin_identity_pool_id" {
  value = aws_cognito_identity_pool.administradores.id
}

output "clientes_login_domain" {
  value = aws_cognito_user_pool_domain.clientes.domain
}

output "admin_login_domain" {
  value = aws_cognito_user_pool_domain.administradores.domain
}