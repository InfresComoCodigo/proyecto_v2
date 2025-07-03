# Variables para el módulo security

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDRs de las subnets privadas"
  type        = list(string)
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "villa-alfredo"
}

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags adicionales"
  type        = map(string)
  default     = {}
}

variable "rds_security_group_id" {
  description = "ID del security group de RDS"
  type        = string
  default     = null
}
