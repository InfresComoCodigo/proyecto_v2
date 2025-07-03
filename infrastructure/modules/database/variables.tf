###################################################################
# VARIABLES GENERALES
###################################################################
variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Entorno (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

###################################################################
# VARIABLES DE RED
###################################################################
variable "vpc_id" {
  description = "ID de la VPC donde se creará la base de datos"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subredes privadas para el DB subnet group"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "Bloques CIDR permitidos para acceder a la base de datos"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "allowed_security_groups" {
  description = "Security groups permitidos para acceder a la base de datos"
  type        = list(string)
  default     = []
}

###################################################################
# VARIABLES DE BASE DE DATOS
###################################################################
variable "database_name" {
  description = "Nombre de la base de datos inicial"
  type        = string
  default     = "iac"
}

variable "master_username" {
  description = "Nombre de usuario maestro"
  type        = string
  default     = "admin"
}

variable "master_password" {
  description = "Contraseña del usuario maestro"
  type        = string
  sensitive   = true
}

variable "mysql_version" {
  description = "Versión de MySQL"
  type        = string
  default     = "8.0.35"
}

variable "instance_class" {
  description = "Clase de instancia RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Almacenamiento inicial en GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Máximo almacenamiento para auto-scaling en GB"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Tipo de almacenamiento (gp2, gp3, io1)"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Habilitar encriptación del almacenamiento"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS Key ID para encriptación"
  type        = string
  default     = null
}

variable "multi_az" {
  description = "Habilitar Multi-AZ para alta disponibilidad"
  type        = bool
  default     = true
}

###################################################################
# VARIABLES DE PARÁMETROS
###################################################################
variable "parameter_group_family" {
  description = "Familia del parameter group"
  type        = string
  default     = "mysql8.0"
}

variable "max_connections" {
  description = "Número máximo de conexiones"
  type        = string
  default     = "100"
}

variable "option_group_name" {
  description = "Nombre del option group"
  type        = string
  default     = null
}

###################################################################
# VARIABLES DE BACKUP Y MANTENIMIENTO
###################################################################
variable "backup_retention_period" {
  description = "Período de retención de backups en días"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Ventana de backup (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Ventana de mantenimiento (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "auto_minor_version_upgrade" {
  description = "Habilitar upgrades automáticos de versiones menores"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Protección contra eliminación"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Omitir snapshot final al eliminar"
  type        = bool
  default     = false
}

###################################################################
# VARIABLES DE MONITOREO
###################################################################
variable "monitoring_interval" {
  description = "Intervalo de monitoreo mejorado en segundos (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 0 # Disabled by default to avoid IAM role issues

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "El intervalo de monitoreo debe ser 0, 1, 5, 10, 15, 30, o 60 segundos."
  }
}

variable "performance_insights_enabled" {
  description = "Habilitar Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Período de retención de Performance Insights en días"
  type        = number
  default     = 7
}

variable "enable_cloudwatch_logs" {
  description = "Habilitar CloudWatch Logs"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Días de retención de logs en CloudWatch"
  type        = number
  default     = 30
}

###################################################################
# VARIABLES DE SECRETS MANAGER
###################################################################
variable "create_secrets_manager" {
  description = "Crear secreto en AWS Secrets Manager para las credenciales"
  type        = bool
  default     = true
}
