###################################################################
# VARIABLES - CDN Module
###################################################################

# Variables básicas del proyecto
variable "project_name" {
    description = "Nombre del proyecto"
    type        = string
}

variable "environment" {
    description = "Entorno de despliegue (dev, staging, prod)"
    type        = string
}

variable "tags" {
    description = "Tags comunes para todos los recursos"
    type        = map(string)
    default     = {}
}

# Configuración del origen (API Gateway)
variable "api_gateway_domain_name" {
    description = "Nombre de dominio del API Gateway (sin protocolo)"
    type        = string
    
    validation {
        condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\-\\.]*[a-zA-Z0-9]$", split("/", var.api_gateway_domain_name)[0]))
        error_message = "api_gateway_domain_name debe ser un dominio válido (sin paths)."
    }
}

# Configuración de origen S3 (nuevo)
variable "s3_bucket_regional_domain_name" {
    description = "Nombre de dominio regional del bucket S3 para CloudFront"
    type        = string
    default     = null
}

variable "s3_origin_access_control_id" {
    description = "ID del Origin Access Control para acceso a S3"
    type        = string
    default     = null
}

variable "primary_origin" {
    description = "Origen principal para el comportamiento por defecto (s3 o api_gateway)"
    type        = string
    default     = "s3"
    
    validation {
        condition     = contains(["s3", "api_gateway"], var.primary_origin)
        error_message = "primary_origin debe ser 's3' o 'api_gateway'."
    }
}

variable "enable_dual_origin" {
    description = "Habilitar configuración de doble origen (S3 + API Gateway)"
    type        = bool
    default     = true
}

variable "custom_headers" {
    description = "Headers personalizados para enviar al origen"
    type = list(object({
        name  = string
        value = string
    }))
    default = []
}

# Configuración de cache behavior
variable "viewer_protocol_policy" {
    description = "Política de protocolo para viewers (allow-all, redirect-to-https, https-only)"
    type        = string
    default     = "redirect-to-https"
    
    validation {
        condition = contains(["allow-all", "redirect-to-https", "https-only"], var.viewer_protocol_policy)
        error_message = "viewer_protocol_policy debe ser allow-all, redirect-to-https o https-only."
    }
}

variable "allowed_methods" {
    description = "Métodos HTTP permitidos"
    type        = list(string)
    default     = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
}

variable "cached_methods" {
    description = "Métodos HTTP que se cachean"
    type        = list(string)
    default     = ["GET", "HEAD"]
}

# Configuración de TTL
variable "cache_min_ttl" {
    description = "TTL mínimo de cache en segundos"
    type        = number
    default     = 0
}

variable "cache_default_ttl" {
    description = "TTL por defecto de cache en segundos"
    type        = number
    default     = 86400
}

variable "cache_max_ttl" {
    description = "TTL máximo de cache en segundos"
    type        = number
    default     = 31536000
}

# Configuración de forwarding
variable "forward_query_string" {
    description = "Si se deben reenviar query strings al origen"
    type        = bool
    default     = true
}

variable "forward_headers" {
    description = "Lista de headers a reenviar al origen"
    type        = list(string)
    default     = ["*"]
}

variable "forward_cookies" {
    description = "Configuración de cookies (none, whitelist, all)"
    type        = string
    default     = "all"
    
    validation {
        condition = contains(["none", "whitelist", "all"], var.forward_cookies)
        error_message = "forward_cookies debe ser none, whitelist o all."
    }
}

# Configuración de compresión
variable "enable_compression" {
    description = "Habilitar compresión automática"
    type        = bool
    default     = true
}

# Cache behaviors adicionales
variable "cache_behaviors" {
    description = "Cache behaviors adicionales para rutas específicas"
    type = list(object({
        path_pattern           = string
        viewer_protocol_policy = string
        allowed_methods        = list(string)
        cached_methods         = list(string)
        min_ttl               = number
        default_ttl           = number
        max_ttl               = number
        forward_query_string  = bool
        forward_headers       = list(string)
        forward_cookies       = string
        compress              = bool
    }))
    default = []
}

# Funciones Edge
variable "edge_functions" {
    description = "Funciones de CloudFront Edge"
    type = list(object({
        event_type   = string
        function_arn = string
    }))
    default = []
}

variable "create_edge_function" {
    description = "Crear función Edge para manipulación de headers"
    type        = bool
    default     = false
}

variable "edge_function_code" {
    description = "Código personalizado para la función Edge"
    type        = string
    default     = null
}

# Restricciones geográficas
variable "geo_restriction_type" {
    description = "Tipo de restricción geográfica (none, whitelist, blacklist)"
    type        = string
    default     = "none"
    
    validation {
        condition = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
        error_message = "geo_restriction_type debe ser none, whitelist o blacklist."
    }
}

variable "geo_restriction_locations" {
    description = "Lista de códigos de países para restricción geográfica"
    type        = list(string)
    default     = []
}

# Configuración SSL
variable "ssl_certificate_arn" {
    description = "ARN del certificado SSL de ACM (opcional)"
    type        = string
    default     = null
}

variable "minimum_protocol_version" {
    description = "Versión mínima del protocolo TLS"
    type        = string
    default     = "TLSv1.2_2021"
}

# Configuración general
variable "enable_ipv6" {
    description = "Habilitar soporte IPv6"
    type        = bool
    default     = true
}

variable "default_root_object" {
    description = "Objeto raíz por defecto"
    type        = string
    default     = null
}

variable "domain_aliases" {
    description = "Lista de dominios alternativos (CNAME)"
    type        = list(string)
    default     = []
}

variable "price_class" {
    description = "Clase de precios de CloudFront (PriceClass_All, PriceClass_200, PriceClass_100)"
    type        = string
    default     = "PriceClass_100"
    
    validation {
        condition = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
        error_message = "price_class debe ser PriceClass_All, PriceClass_200 o PriceClass_100."
    }
}

# Configuración de logging
variable "enable_logging" {
    description = "Habilitar logging de CloudFront"
    type        = bool
    default     = false
}

variable "log_bucket_domain_name" {
    description = "Nombre de dominio del bucket S3 para logs"
    type        = string
    default     = null
}

variable "log_prefix" {
    description = "Prefijo para archivos de log"
    type        = string
    default     = "cloudfront-logs/"
}

# Páginas de error personalizadas
variable "custom_error_responses" {
    description = "Respuestas de error personalizadas"
    type = list(object({
        error_code            = number
        response_code         = number
        response_page_path    = string
        error_caching_min_ttl = number
    }))
    default = []
}

# Monitoreo
variable "enable_monitoring" {
    description = "Habilitar CloudWatch alarms"
    type        = bool
    default     = false
}

variable "origin_latency_threshold" {
    description = "Umbral de latencia del origen en milisegundos"
    type        = number
    default     = 5000
}

variable "error_rate_threshold" {
    description = "Umbral de tasa de errores 4xx en porcentaje"
    type        = number
    default     = 10
}

variable "alarm_topic_arn" {
    description = "ARN del topic SNS para notificaciones de alarmas"
    type        = string
    default     = null
}

# Configuración de WAF
variable "web_acl_arn" {
    description = "ARN del WAF Web ACL para asociar con CloudFront (opcional)"
    type        = string
    default     = null
}
# variable "web_acl_id" is deprecated, use web_acl_arn instead
variable "web_acl_id" {
    description = "(deprecated) ID del WAF Web ACL. Proporcione web_acl_arn en su lugar"
    type        = string
    default     = null
}

variable "enable_waf" {
    description = "Habilitar WAF para CloudFront"
    type        = bool
    default     = false
}
