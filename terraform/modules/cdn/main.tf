# Recursos principales del módulo de CDN (CloudFront)

# 1. Origin Access Control (OAC) - El método moderno y recomendado para dar acceso a S3.
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.s3_origin_id}-oac"
  description                       = "OAC para el bucket ${var.s3_origin_id}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 2. Distribución de CloudFront
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Distribución para ${var.s3_origin_id}"
  default_root_object = "index.html" # Objeto por defecto al acceder a la raíz

  # Origen: apunta a nuestro bucket S3
  origin {
    domain_name              = var.s3_origin_domain_name
    origin_id                = var.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # Comportamiento del caché (Default)
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.s3_origin_id

    # Redirige todo el tráfico HTTP a HTTPS
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    min_ttl                = 0
    default_ttl            = 3600 # 1 hora
    max_ttl                = 86400 # 24 horas

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Restricciones geográficas (opcional, aquí sin restricciones)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Configuración de la vista (sin ACM ni dominio personalizado)
  # Usará el certificado *.cloudfront.net por defecto
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

# 3. Política del Bucket S3: Se genera aquí pero se aplica al bucket del otro módulo.
# Esto permite que la distribución de CloudFront lea los objetos del bucket.
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.s3_origin_id}/*"] # Acceso a todos los objetos dentro del bucket

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

# Recurso para aplicar la política al bucket S3
resource "aws_s3_bucket_policy" "allow_cloudfront_access" {
  bucket = var.s3_origin_id
  policy = data.aws_iam_policy_document.s3_policy.json
}