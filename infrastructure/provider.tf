terraform {
  # Versión mínima de Terraform que admite tu código
  required_version = ">= 1.0"

  # Proveedores que se descargarán en `terraform init`
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Proveedor de AWS
provider "aws" {
  # Región de AWS donde se desplegarán los recursos
  region = var.aws_region
}

# Proveedor específico para WAF CloudFront (debe estar en us-east-1)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
