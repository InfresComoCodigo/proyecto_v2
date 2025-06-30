# Variables para el módulo compute

variable "security_group_id" {
  description = "ID del security group para las instancias EC2"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC donde se desplegarán las instancias"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Lista de IDs de subnets privadas para las instancias EC2 (debe tener exactamente 2 elementos: [zona-a, zona-b])"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) == 2
    error_message = "Debe proporcionar exactamente 2 subnet IDs: uno para us-east-1a y otro para us-east-1b."
  }
}

variable "environment" {
  description = "Ambiente de despliegue (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t2.micro"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "villa-alfredo"
}

variable "tags" {
  description = "Tags adicionales para los recursos"
  type        = map(string)
  default     = {}
}

variable "key_name" {
  description = "Nombre del key pair para acceso SSH (opcional)"
  type        = string
  default     = null
}

variable "ami_id" {
  description = "ID de la AMI a usar para las instancias"
  type        = string
  default     = "ami-05ffe3c48a9991133"  # Amazon Linux 2023 en us-east-1
}

variable "user_data_file" {
  description = "Ruta al archivo de user data"
  type        = string
  default     = "modules/compute/user_data.sh"
}

variable "enable_monitoring" {
  description = "Habilitar monitoreo detallado de CloudWatch"
  type        = bool
  default     = false
}

# Variables para Auto Scaling Group
variable "min_size" {
  description = "Número mínimo de instancias adicionales en el ASG (además de las 2 fijas)"
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Número máximo de instancias adicionales en el ASG (además de las 2 fijas)"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Número deseado de instancias adicionales en el ASG inicialmente"
  type        = number
  default     = 0
}

variable "health_check_grace_period" {
  description = "Período de gracia para health checks del ASG (segundos)"
  type        = number
  default     = 300
}

variable "scale_up_threshold" {
  description = "Umbral de CPU para escalar hacia arriba (%)"
  type        = number
  default     = 70
}

variable "scale_down_threshold" {
  description = "Umbral de CPU para escalar hacia abajo (%)"
  type        = number
  default     = 30
}

# Variable para ALB Target Group
variable "target_group_arn" {
  description = "ARN del target group del ALB para registrar automáticamente las instancias del ASG"
  type        = string
  default     = null
}
