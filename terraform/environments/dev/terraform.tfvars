# Valores de las variables para el entorno de desarrollo (dev)

# Nombre único global para tu bucket. Cámbialo por algo único.
frontend_bucket_name = "mi-app-reservas-frontend-dev-20250621"

# Etiquetas para identificar y organizar los recursos
common_tags = {
  Environment = "dev"
  Project     = "ReservasPlatform"
  ManagedBy   = "Terraform"
}

# Región de AWS
aws_region = "us-east-1"

# Nombre del proyecto
project_name = "villa-alfredo-dev"
