# C:\Users\lucia\iac\proyecto_v2\terraform\variables.tf

variable "frontend_bucket_name" {
  description = "El nombre único para el bucket S3 del frontend."
  type        = string
}

variable "common_tags" {
  description = "Etiquetas comunes para aplicar a todos los recursos."
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

