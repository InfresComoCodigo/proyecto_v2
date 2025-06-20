# Entradas para el módulo de CDN

variable "s3_origin_id" {
  description = "El ID del bucket S3 que funcionará como origen."
  type        = string
}

variable "s3_origin_domain_name" {
  description = "El nombre de dominio regional del bucket S3 de origen."
  type        = string
}

variable "tags" {
  description = "Etiquetas comunes para aplicar a todos los recursos."
  type        = map(string)
  default     = {}
}