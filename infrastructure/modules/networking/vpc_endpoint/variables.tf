# Variables para VPC Endpoints

variable "vpc_id" {
  description = "ID de la VPC donde crear los VPC endpoints"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs de las subnets privadas donde se crearán los endpoints"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "IDs de las route tables privadas para el endpoint de S3"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID del security group para los VPC endpoints"
  type        = string
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
