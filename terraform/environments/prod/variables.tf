variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "env" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "172.16.0.0/16"
}

variable "azs" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["us-east-1a","us-east-1b","us-east-1c"]
}

variable "public_subnets" {
  description = "CIDRs for public subnets"
  type        = list(string)
  default     = ["172.16.0.0/24","172.16.1.0/24","172.16.2.0/24"]
}

variable "private_subnets" {
  description = "CIDRs for private subnets"
  type        = list(string)
  default     = ["172.16.10.0/24","172.16.11.0/24","172.16.12.0/24"]
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {
    Project = "aws-reservas-platform"
    Env     = "prod"
  }
}

# Añadir una descripción y tipo a las variables de la base de datos
variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_username" {
  description = "The username for the database"
  type        = string
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}

variable "engine_version" {
  description = "The version of the database engine"
  type        = string
  default     = "8.0"
}

variable "instance_class" {
  description = "The class of the database instance"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "The amount of storage to be allocated for the database"
  type        = number
  default     = 20
}

# Asegúrate de que las subredes privadas estén correctamente definidas
variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

# Añadir una descripción y tipo para la variable 'project'
variable "project" {
  description = "Project name"
  type        = string
  default     = "reservas"
}