###################################################################
# VARIABLES PARA MÓDULO STORAGE (S3)
###################################################################

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Ambiente de deployment"
  type        = string
}

variable "tags" {
  description = "Tags adicionales para los recursos"
  type        = map(string)
  default     = {}
}

###################################################################
# CONFIGURACIONES DE S3
###################################################################

variable "enable_versioning" {
  description = "Habilitar versionado en el bucket S3"
  type        = bool
  default     = true
}

variable "enable_lifecycle_policy" {
  description = "Habilitar políticas de lifecycle en S3"
  type        = bool
  default     = true
}

variable "create_sample_files" {
  description = "Crear archivos de ejemplo en el bucket"
  type        = bool
  default     = false
}

variable "enable_cors" {
  description = "Habilitar configuración CORS en el bucket"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "Orígenes permitidos para CORS"
  type        = list(string)
  default     = ["*"]
}

variable "kms_key_id" {
  description = "ID de la clave KMS para cifrado de S3"
  type        = string
  default     = null
}

###################################################################
# CONFIGURACIONES DE CONECTIVIDAD
###################################################################

variable "s3_vpc_endpoint_id" {
  description = "ID del VPC endpoint para S3"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN de la distribución de CloudFront"
  type        = string
}

variable "ec2_instance_roles" {
  description = "ARNs de los roles de las instancias EC2 para acceso a S3"
  type        = list(string)
  default     = null
}

###################################################################
# CONFIGURACIONES DE VPC
###################################################################

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subredes privadas"
  type        = list(string)
}
