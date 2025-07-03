###################################################################
# VARIABLES - WAF Module
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

variable "kms_key_id" {
  description = "ID de la clave KMS para cifrado de logs de WAF"
  type        = string
  default     = null
}

variable "enable_logging" {
  description = "Habilitar logging de WAF"
  type        = bool
  default     = true
}

###################################################################
# CONFIGURACIÓN DE REGLAS WAF
###################################################################

variable "excluded_common_rules" {
  description = "Lista de reglas del Core Rule Set a excluir"
  type        = list(string)
  default     = []
}

variable "enable_sql_injection_protection" {
  description = "Habilitar protección contra SQL Injection"
  type        = bool
  default     = true
}

variable "enable_rate_limiting" {
  description = "Habilitar rate limiting"
  type        = bool
  default     = true
}

variable "rate_limit_requests" {
  description = "Número máximo de requests por IP en 5 minutos"
  type        = number
  default     = 2000
}

###################################################################
# CONFIGURACIÓN GEOGRÁFICA
###################################################################

variable "blocked_countries" {
  description = "Lista de códigos de países a bloquear (ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for country in var.blocked_countries : can(regex("^[A-Z]{2}$", country))
    ])
    error_message = "Los códigos de países deben ser de 2 letras en mayúsculas (ej: US, CA, MX)."
  }
}

variable "allowed_countries" {
  description = "Lista de códigos de países permitidos (ISO 3166-1 alpha-2). Si se especifica, todos los demás países serán bloqueados"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for country in var.allowed_countries : can(regex("^[A-Z]{2}$", country))
    ])
    error_message = "Los códigos de países deben ser de 2 letras en mayúsculas (ej: US, CA, MX)."
  }
}

###################################################################
# CONFIGURACIÓN DE IP ADDRESSES
###################################################################

variable "blocked_ip_addresses" {
  description = "Lista de direcciones IP o CIDR blocks a bloquear"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for ip in var.blocked_ip_addresses : can(cidrhost(ip, 0))
    ])
    error_message = "Todas las direcciones IP deben estar en formato CIDR válido (ej: 192.168.1.1/32, 10.0.0.0/8)."
  }
}

variable "allowed_ip_addresses" {
  description = "Lista de direcciones IP o CIDR blocks permitidos (whitelist). Si se especifica, todas las demás IPs serán bloqueadas"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for ip in var.allowed_ip_addresses : can(cidrhost(ip, 0))
    ])
    error_message = "Todas las direcciones IP deben estar en formato CIDR válido (ej: 192.168.1.1/32, 10.0.0.0/8)."
  }
}

###################################################################
# CONFIGURACIÓN DE USER AGENTS
###################################################################

variable "blocked_user_agents" {
  description = "Lista de User Agents a bloquear (strings que contengan estos valores serán bloqueados)"
  type        = list(string)
  default     = []
}

###################################################################
# CONFIGURACIÓN DE MONITOREO Y LOGGING
###################################################################

variable "enable_cloudwatch_metrics" {
  description = "Habilitar métricas de CloudWatch para WAF"
  type        = bool
  default     = true
}

variable "enable_sampled_requests" {
  description = "Habilitar muestreo de requests en WAF"
  type        = bool
  default     = true
}

variable "enable_waf_logging" {
  description = "Habilitar logging de WAF a CloudWatch"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Días de retención para los logs de WAF"
  type        = number
  default     = 30
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "log_retention_days debe ser uno de los valores permitidos por CloudWatch Logs."
  }
}

variable "redacted_fields" {
  description = "Campos a ocultar en los logs de WAF"
  type = list(object({
    type = string # "single_header", "uri_path", "query_string"
    name = optional(string) # Solo requerido para single_header
  }))
  default = []
}

###################################################################
# CONFIGURACIÓN AVANZADA
###################################################################

variable "custom_rules" {
  description = "Reglas personalizadas adicionales para WAF"
  type = list(object({
    name        = string
    priority    = number
    action_type = string # "allow", "block", "count"
    statement = object({
      type = string # Tipo de statement, ej: "byte_match", "geo_match", etc.
      # Configuración específica del statement se manejará caso por caso
    })
  }))
  default = []
}

variable "enable_aws_managed_rules" {
  description = "Configuración de reglas administradas por AWS"
  type = object({
    common_rule_set           = optional(bool, true)
    known_bad_inputs         = optional(bool, true)
    sql_injection           = optional(bool, true)
    linux_rule_set          = optional(bool, false)
    unix_rule_set           = optional(bool, false)
    windows_rule_set        = optional(bool, false)
    php_rule_set            = optional(bool, false)
    wordpress_rule_set      = optional(bool, false)
  })
  default = {}
}
