variable "env" {
  description = "Environment (dev, prod)"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN de SNS para notificaciones"
  type        = string
  default     = ""
}