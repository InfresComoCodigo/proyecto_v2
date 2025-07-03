###################################################################
# VARIABLES - Configuración del módulo VPC
###################################################################

variable "project_name" {
    description = "Nombre del proyecto para etiquetar recursos"
    type        = string
    default     = "villa-alfredo"
}

variable "environment" {
    description = "Entorno de despliegue (dev, staging, prod)"
    type        = string
    default     = "dev"
}

variable "vpc_cidr" {
    description = "Bloque CIDR para la VPC"
    type        = string
    default     = "10.0.0.0/16"
}

variable "enable_dns_support" {
    description = "Habilitar soporte DNS en la VPC"
    type        = bool
    default     = true
}

variable "enable_dns_hostnames" {
    description = "Habilitar hostnames DNS en la VPC"
    type        = bool
    default     = true
}

variable "create_nat_gateway" {
    description = "Si crear NAT Gateways y subredes públicas"
    type        = bool
    default     = true
}

variable "map_public_ip_on_launch" {
    description = "Asignar IP pública automáticamente en subredes públicas"
    type        = bool
    default     = false
}

variable "tags" {
    description = "Tags adicionales para aplicar a todos los recursos"
    type        = map(string)
    default     = {}
}

variable "availability_zones" {
    description = "Lista de zonas de disponibilidad a usar"
    type        = list(string)
    default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
    description = "Lista de bloques CIDR para subredes públicas"
    type        = list(string)
    default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
    description = "Lista de bloques CIDR para subredes privadas"
    type        = list(string)
    default     = ["10.0.101.0/24", "10.0.102.0/24"]
}
