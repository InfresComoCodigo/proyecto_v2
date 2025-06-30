###################################################################
# VARIABLES - Configuración del módulo ALB
###################################################################

variable "vpc_id" {
  description = "ID de la VPC donde se desplegará el ALB"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs de las subredes públicas para el ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID del security group para el ALB"
  type        = string
}

variable "target_instance_ids" {
  description = "IDs de las instancias EC2 para el target group (opcional)"
  type        = list(string)
  default     = []
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

variable "alb_port" {
  description = "Puerto del ALB para recibir tráfico"
  type        = number
  default     = 80
}

variable "target_port" {
  description = "Puerto en las instancias EC2"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Ruta para health checks"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Intervalo de health checks (segundos)"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout de health checks (segundos)"
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Número de health checks exitosos para considerar healthy"
  type        = number
  default     = 2
}

variable "unhealthy_threshold" {
  description = "Número de health checks fallidos para considerar unhealthy"
  type        = number
  default     = 2
}
