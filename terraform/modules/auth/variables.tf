###################################################################
# VARIABLES GENERALES
###################################################################

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

###################################################################
# CONFIGURACIÓN DEL USER POOL
###################################################################

variable "password_minimum_length" {
  description = "Longitud mínima de la contraseña"
  type        = number
  default     = 8
}

variable "password_require_lowercase" {
  description = "Requerir letras minúsculas en la contraseña"
  type        = bool
  default     = true
}

variable "password_require_numbers" {
  description = "Requerir números en la contraseña"
  type        = bool
  default     = true
}

variable "password_require_symbols" {
  description = "Requerir símbolos en la contraseña"
  type        = bool
  default     = true
}

variable "password_require_uppercase" {
  description = "Requerir letras mayúsculas en la contraseña"
  type        = bool
  default     = true
}

variable "enable_mfa" {
  description = "Habilitar autenticación multifactor"
  type        = bool
  default     = false
}

variable "challenge_required_on_new_device" {
  description = "Requerir challenge en dispositivos nuevos"
  type        = bool
  default     = false
}

variable "device_only_remembered_on_user_prompt" {
  description = "Recordar dispositivo solo cuando el usuario lo solicite"
  type        = bool
  default     = false
}

###################################################################
# CONFIGURACIÓN DE LAMBDA TRIGGERS
###################################################################

variable "enable_lambda_triggers" {
  description = "Habilitar triggers de Lambda"
  type        = bool
  default     = false
}

variable "pre_sign_up_lambda_arn" {
  description = "ARN del Lambda para pre sign up"
  type        = string
  default     = null
}

variable "post_confirmation_lambda_arn" {
  description = "ARN del Lambda para post confirmation"
  type        = string
  default     = null
}

###################################################################
# CONFIGURACIÓN DEL CLIENT (API Gateway)
###################################################################

variable "access_token_validity" {
  description = "Validez del access token en horas"
  type        = number
  default     = 24
}

variable "id_token_validity" {
  description = "Validez del ID token en horas"
  type        = number
  default     = 24
}

variable "refresh_token_validity" {
  description = "Validez del refresh token en días"
  type        = number
  default     = 30
}

variable "callback_urls" {
  description = "URLs de callback para OAuth (solo necesario si usas OAuth flows como 'code' o 'implicit')"
  type        = list(string)
  default     = []
}

variable "logout_urls" {
  description = "URLs de logout para OAuth (solo necesario si usas OAuth flows)"
  type        = list(string)
  default     = []
}

variable "allowed_oauth_flows" {
  description = "Flujos OAuth permitidos. Dejar vacío para uso solo con API Gateway. Usar ['code'] para UI hospedada."
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for flow in var.allowed_oauth_flows : contains(["code", "implicit", "client_credentials"], flow)
    ])
    error_message = "Los flujos OAuth permitidos son: code, implicit, client_credentials."
  }
}

variable "allowed_oauth_scopes" {
  description = "Scopes OAuth permitidos (solo necesario si usas OAuth flows)"
  type        = list(string)
  default     = []
}

variable "supported_identity_providers" {
  description = "Proveedores de identidad soportados"
  type        = list(string)
  default     = ["COGNITO"]
}

variable "read_attributes" {
  description = "Atributos que el cliente puede leer"
  type        = list(string)
  default     = ["email", "email_verified"]
}

variable "write_attributes" {
  description = "Atributos que el cliente puede escribir"
  type        = list(string)
  default     = ["email"]
}

###################################################################
# CONFIGURACIÓN DEL WEB CLIENT
###################################################################

variable "create_web_client" {
  description = "Crear cliente para aplicaciones web/móviles"
  type        = bool
  default     = true
}

variable "web_callback_urls" {
  description = "URLs de callback para el cliente web"
  type        = list(string)
  default     = ["http://localhost:3000/callback"]
}

variable "web_logout_urls" {
  description = "URLs de logout para el cliente web"
  type        = list(string)
  default     = ["http://localhost:3000/logout"]
}

###################################################################
# CONFIGURACIÓN DEL IDENTITY POOL
###################################################################

variable "create_identity_pool" {
  description = "Crear Identity Pool para acceso a recursos AWS"
  type        = bool
  default     = false
}

variable "allow_unauthenticated_identities" {
  description = "Permitir identidades no autenticadas"
  type        = bool
  default     = false
}
