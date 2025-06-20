variable "env" {
  description = "Entorno (dev/prod)"
  type        = string
}

variable "private_subnets" {
  description = "IDs de subredes privadas"
  type        = list(string)
}

variable "ec2_sg_id" {
  description = "ID del Security Group para EC2"
  type        = string
}

variable "ami_id" {
  description = "AMI ID para las instancias"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nombre del key pair SSH"
  type        = string
  default     = ""
}

variable "volume_size" {
  description = "Tamaño del disco raíz (GB)"
  type        = number
  default     = 20
}

variable "desired_capacity" {
  description = "Número deseado de instancias"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Mínimo de instancias en el ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Máximo de instancias en el ASG"
  type        = number
  default     = 4
}

variable "enable_user_data" {
  description = "Habilitar script de inicialización"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags comunes"
  type        = map(string)
}