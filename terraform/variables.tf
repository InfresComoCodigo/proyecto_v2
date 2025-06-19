# Variable para la región de AWS
variable "aws_region" {
  description = "La región de AWS donde se van a desplegar los recursos"
  type        = string
}

# Variable para el nombre del proyecto, para nombrar los recursos de Cognito
variable "project_name" {
  description = "Nombre del proyecto para prefijar los recursos"
  type        = string
}
