# Configuración del proveedor AWS
provider "aws" {
  region = var.aws_region  # Región de AWS definida en terraform.tfvars
}

# Llamada al módulo auth donde se configuran los recursos de Cognito (User Pools, Identity Pools)
module "auth" {
  source       = "./modules/auth"  # Ruta al módulo `auth` donde definimos Cognito
  project_name = var.project_name  # Nombre del proyecto para prefijar los recursos (de terraform.tfvars)
}