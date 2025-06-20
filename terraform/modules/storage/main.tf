# Recursos principales del módulo de storage (S3)

# Crea un bucket S3 para alojar el contenido estático del frontend.
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name
  tags   = var.tags
}

# Bloquea todo el acceso público al bucket.
# La seguridad es primordial; solo CloudFront (a través de OAC) podrá acceder.
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# La política del bucket se adjuntará dinámicamente desde el módulo CDN
# para permitir el acceso únicamente a la distribución de CloudFront específica.
# Por lo tanto, no definimos una política aquí directamente.