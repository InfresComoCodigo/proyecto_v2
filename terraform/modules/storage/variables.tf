# Entradas para el módulo de storage

variable "bucket_name" {
  description = "El nombre único para el bucket S3. Se usará para el frontend."
  type        = string
}

variable "tags" {
  description = "Etiquetas comunes para aplicar a todos los recursos."
  type        = map(string)
  default     = {}
}