###################################################################
# VARIABLES
###################################################################

variable "aws_region" {
    description = "Región de AWS"
    type        = string
    default     = "us-east-1"
}

variable "environment" {
    description = "Entorno de despliegue"
    type        = string
    default     = "dev"
}

variable "project_name" {
    description = "Nombre del proyecto"
    type        = string
    default     = "villa-alfredo"
}

variable "common_tags" {
    description = "Tags comunes para todos los recursos"
    type        = map(string)
    default     = {
        Team        = "Infrastructure"
        Project     = "VillaAlfredo"
        ManagedBy   = "terraform"
    }
}

variable "key_pair_name" {
    description = "Nombre del key pair para acceso SSH a las instancias (opcional)"
    type        = string
    default     = null
}

###################################################################
# VARIABLES DE BASE DE DATOS
###################################################################

variable "db_password" {
    description = "Contraseña para el usuario maestro de la base de datos MySQL"
    type        = string
    sensitive   = true
    
    validation {
        condition     = length(var.db_password) >= 8
        error_message = "La contraseña debe tener al menos 8 caracteres."
    }
}