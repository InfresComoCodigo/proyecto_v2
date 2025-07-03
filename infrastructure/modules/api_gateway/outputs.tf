###################################################################
# OUTPUTS - API Gateway Module
###################################################################

output "api_gateway_id" {
    description = "ID del API Gateway"
    value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_arn" {
    description = "ARN del API Gateway"
    value       = aws_api_gateway_rest_api.main.arn
}

output "api_gateway_url" {
    description = "URL base del API Gateway"
    value       = aws_api_gateway_stage.main.invoke_url
}

output "api_gateway_stage_name" {
    description = "Nombre del stage del API Gateway"
    value       = aws_api_gateway_stage.main.stage_name
}

output "api_gateway_execution_arn" {
    description = "ARN de ejecución del API Gateway"
    value       = aws_api_gateway_rest_api.main.execution_arn
}

output "cloudwatch_log_group_name" {
    description = "Nombre del grupo de logs de CloudWatch"
    value       = aws_cloudwatch_log_group.api_gateway_logs.name
}

output "cloudwatch_log_group_arn" {
    description = "ARN del grupo de logs de CloudWatch"
    value       = aws_cloudwatch_log_group.api_gateway_logs.arn
}

output "api_gateway_domain_name" {
    description = "Nombre de dominio del API Gateway sin protocolo para CloudFront"
    value       = split("/", replace(replace(aws_api_gateway_stage.main.invoke_url, "https://", ""), "http://", ""))[0]
}

output "api_gateway_path" {
    description = "Path del API Gateway para CloudFront"
    value       = length(split("/", replace(replace(aws_api_gateway_stage.main.invoke_url, "https://", ""), "http://", ""))) > 1 ? "/${join("/", slice(split("/", replace(replace(aws_api_gateway_stage.main.invoke_url, "https://", ""), "http://", "")), 1, length(split("/", replace(replace(aws_api_gateway_stage.main.invoke_url, "https://", ""), "http://", "")))))}" : ""
}

# Información completa del API Gateway
output "api_gateway_info" {
    description = "Información completa del API Gateway"
    value = {
        api_id         = aws_api_gateway_rest_api.main.id
        api_arn        = aws_api_gateway_rest_api.main.arn
        api_url        = aws_api_gateway_stage.main.invoke_url
        stage_name     = aws_api_gateway_stage.main.stage_name
        log_group_name = aws_cloudwatch_log_group.api_gateway_logs.name
        endpoint_type  = var.api_gateway_type
    }
}

###################################################################
# OUTPUTS PARA COGNITO AUTHORIZER
###################################################################

output "cognito_authorizer_id" {
    description = "ID del authorizer de Cognito"
    value       = var.enable_cognito_auth ? aws_api_gateway_authorizer.cognito[0].id : null
}

output "auth_enabled" {
    description = "Indica si la autenticación Cognito está habilitada"
    value       = var.enable_cognito_auth
}

output "public_endpoints_enabled" {
    description = "Indica si los endpoints públicos están habilitados"
    value       = var.create_public_endpoints
}

output "public_base_url" {
    description = "URL base para endpoints públicos (sin autenticación)"
    value       = var.create_public_endpoints ? "${aws_api_gateway_stage.main.invoke_url}/public" : null
}

output "protected_base_url" {
    description = "URL base para endpoints protegidos (requieren autenticación)"
    value       = var.enable_cognito_auth ? aws_api_gateway_stage.main.invoke_url : null
}
