###################################################################
# MÓDULO S3 - Almacenamiento y distribución de contenido
# Arquitectura: EC2 (VPC privada) → VPC Endpoint → S3 → CloudFront
###################################################################

###################################################################
# DATA SOURCES
###################################################################

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

###################################################################
# LOCALS
###################################################################

locals {
  common_tags = {
    Environment = var.environment
    ProjectName = var.project_name
    Module      = "storage"
    ManagedBy   = "terraform"
  }
  
  bucket_name = "${var.project_name}-${var.environment}-content-${random_string.bucket_suffix.result}"
}

###################################################################
# RANDOM STRING PARA BUCKET NAME ÚNICO
###################################################################

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

###################################################################
# S3 BUCKET PRINCIPAL
###################################################################

resource "aws_s3_bucket" "main" {
  bucket = local.bucket_name

  tags = merge(local.common_tags, var.tags, {
    Name        = "${var.project_name}-${var.environment}-main-bucket"
    Purpose     = "Content storage and CloudFront origin"
    AccessType  = "Private with CloudFront and VPC endpoint"
  })
}

###################################################################
# CONFIGURACIÓN DE VERSIONADO
###################################################################

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

###################################################################
# CONFIGURACIÓN DE ENCRIPTACIÓN
###################################################################

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

###################################################################
# BLOQUEO DE ACCESO PÚBLICO
###################################################################

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Random suffix for unique resource naming
###################################################################
# CLOUDFRONT ORIGIN ACCESS CONTROL (OAC)
###################################################################

resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.project_name}-${var.environment}-oac-${random_string.bucket_suffix.result}"
  description                       = "OAC for ${var.project_name} S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

###################################################################
# BUCKET POLICY - Acceso desde VPC Endpoint y CloudFront
###################################################################

data "aws_iam_policy_document" "bucket_policy" {
  # Permitir acceso desde VPC Endpoint (para EC2 instances)
  statement {
    sid    = "AllowVPCEndpointAccess"
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    
    resources = [
      aws_s3_bucket.main.arn,
      "${aws_s3_bucket.main.arn}/*"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = [var.s3_vpc_endpoint_id]
    }
  }
  
  # Permitir acceso desde CloudFront (usando OAC)
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    
    actions = [
      "s3:GetObject"
    ]
    
    resources = [
      "${aws_s3_bucket.main.arn}/*"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [var.cloudfront_distribution_arn]
    }
  }
  
  # Permitir acceso desde instancias EC2 específicas (opcional, como backup)
  dynamic "statement" {
    for_each = var.ec2_instance_roles != null ? [1] : []
    
    content {
      sid    = "AllowEC2InstanceAccess"
      effect = "Allow"
      
      principals {
        type        = "AWS"
        identifiers = var.ec2_instance_roles
      }
      
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      
      resources = [
        aws_s3_bucket.main.arn,
        "${aws_s3_bucket.main.arn}/*"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.bucket_policy.json
  
  depends_on = [aws_s3_bucket_public_access_block.main]
}

###################################################################
# CONFIGURACIÓN DE LIFECYCLE (OPCIONAL)
###################################################################

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  count  = var.enable_lifecycle_policy ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "main_lifecycle_rule"
    status = "Enabled"

    # Filter para aplicar a todos los objetos
    filter {
      prefix = ""
    }

    # Transición a IA después de 30 días
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transición a Glacier después de 90 días
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Eliminar versiones antiguas después de 365 días
    noncurrent_version_expiration {
      noncurrent_days = 365
    }

    # Eliminar uploads incompletos después de 7 días
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

###################################################################
# OBJETOS DE EJEMPLO (OPCIONAL)
###################################################################

resource "aws_s3_object" "sample_files" {
  for_each = var.create_sample_files ? {
    "index.html"    = "text/html"
    "style.css"     = "text/css"
    "script.js"     = "application/javascript"
    "favicon.ico"   = "image/x-icon"
  } : {}

  bucket       = aws_s3_bucket.main.id
  key          = each.key
  content      = each.key == "index.html" ? local.sample_html : "/* Sample ${each.key} file */"
  content_type = each.value
  
  tags = merge(local.common_tags, {
    Name = "sample-${each.key}"
    Type = "Sample file"
  })
}

locals {
  sample_html = <<-EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Villa Alfredo - ${var.environment}</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <header>
        <h1>Villa Alfredo</h1>
        <h2>Ambiente: ${var.environment}</h2>
    </header>
    <main>
        <p>Bienvenido a Villa Alfredo. Este contenido se sirve desde:</p>
        <ul>
            <li>S3 Bucket: ${local.bucket_name}</li>
            <li>A través de CloudFront CDN</li>
            <li>Accesible desde EC2 via VPC Endpoint</li>
        </ul>
        <p>Fecha de deploy: ${timestamp()}</p>
    </main>
    <script src="script.js"></script>
</body>
</html>
EOF
}

###################################################################
# CORS CONFIGURATION (para aplicaciones web)
###################################################################

resource "aws_s3_bucket_cors_configuration" "main" {
  count  = var.enable_cors ? 1 : 0
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
