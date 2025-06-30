###################################################################
# VARIABLES - API Gateway Module
###################################################################

variable "project_name" {
    description = "Nombre del proyecto"
    type        = string
}

variable "environment" {
    description = "Entorno de despliegue"
    type        = string
}

variable "alb_dns_name" {
    description = "DNS name del Application Load Balancer"
    type        = string
}

variable "api_gateway_type" {
    description = "Tipo de API Gateway (REGIONAL o EDGE)"
    type        = string
    default     = "REGIONAL"
}

variable "stage_name" {
    description = "Nombre del stage de API Gateway"
    type        = string
    default     = "api"
}

variable "throttle_rate_limit" {
    description = "Límite de rate para throttling"
    type        = number
    default     = 1000
}

variable "throttle_burst_limit" {
    description = "Límite de burst para throttling"
    type        = number
    default     = 2000
}

variable "enable_logging" {
    description = "Habilitar logging de API Gateway"
    type        = bool
    default     = true
}

variable "log_level" {
    description = "Nivel de logging (ERROR, INFO)"
    type        = string
    default     = "INFO"
}

variable "tags" {
    description = "Tags para los recursos"
    type        = map(string)
    default     = {}
}

###################################################################
# VARIABLES PARA COGNITO AUTH
###################################################################

variable "enable_cognito_auth" {
    description = "Habilitar autenticación con Cognito User Pools"
    type        = bool
    default     = false
}

variable "cognito_user_pool_arn" {
    description = "ARN del User Pool de Cognito para autenticación"
    type        = string
    default     = null
}

variable "authorizer_ttl" {
    description = "TTL en segundos para el resultado del authorizer"
    type        = number
    default     = 300
}

variable "create_public_endpoints" {
    description = "Crear endpoints públicos (sin autenticación) bajo /public/*"
    type        = bool
    default     = false
}
