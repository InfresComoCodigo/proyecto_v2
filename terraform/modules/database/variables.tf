variable "project" {
  description = "Nombre del proyecto para etiquetas"
  type        = string
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
}

variable "db_username" {
  description = "Usuario de la base de datos"
  type        = string
}

variable "db_password" {
  description = "Contraseña de la base de datos"
  type        = string
  sensitive   = true
}

variable "engine_version" {
  description = "Versión de MySQL"
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "Clase de instancia RDS"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Tamaño de almacenamiento (GB)"
  type        = number
  default     = 20
}

variable "private_subnet_ids" {
  description = "Subredes privadas para Multi-AZ"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups permitidos"
  type        = list(string)
  default     = null
}