###################################################################
# RANDOM SUFFIX FOR UNIQUE NAMING
###################################################################

# Random suffix for unique resource naming
resource "random_string" "alb_suffix" {
  length  = 6
  special = false
  upper   = false
}

###################################################################
# APPLICATION LOAD BALANCER
###################################################################

resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb-${random_string.alb_suffix.result}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
  
  # Configuración de desync mitigation para cumplir CKV_AWS_328
  desync_mitigation_mode = "strictest"

  # Habilitar logging de acceso para auditoria (CKV_AWS_91)
  access_logs {
    bucket  = var.access_logs_bucket != null ? var.access_logs_bucket : aws_s3_bucket.alb_logs[0].bucket
    prefix  = var.access_logs_prefix
    enabled = true  # Force enable access logs for compliance
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Type        = "ApplicationLoadBalancer"
  })
}

###################################################################
# TARGET GROUP
###################################################################

resource "aws_lb_target_group" "ec2_targets" {
  name     = "${var.project_name}-${var.environment}-tg-${random_string.alb_suffix.result}"
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = "200,301,302"  # Ampliar códigos de respuesta válidos para cumplir CKV_AWS_261
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-target-group"
    Environment = var.environment
  })
}

###################################################################
# TARGET GROUP ATTACHMENTS - Instancias fijas (opcional)
###################################################################

resource "aws_lb_target_group_attachment" "ec2_targets" {
  count            = length(var.target_instance_ids)
  target_group_arn = aws_lb_target_group.ec2_targets.arn
  target_id        = var.target_instance_ids[count.index]
  port             = var.target_port
}

###################################################################
# LISTENER
###################################################################

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.alb_port
  protocol          = var.alb_port == 443 ? "HTTPS" : "HTTP"
  ssl_policy        = var.alb_port == 443 ? "ELBSecurityPolicy-TLS-1-2-2017-01" : null  # Política TLS segura para cumplir CKV2_AWS_74
  certificate_arn   = var.alb_port == 443 ? var.ssl_certificate_arn : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_targets.arn
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-listener"
    Environment = var.environment
  })
}

###################################################################
# S3 BUCKET FOR ALB ACCESS LOGS
###################################################################

# Data source for ALB service account
data "aws_elb_service_account" "main" {}

# S3 bucket for ALB access logs
resource "aws_s3_bucket" "alb_logs" {
  count  = var.access_logs_bucket == null ? 1 : 0
  bucket = "${var.project_name}-${var.environment}-alb-logs-${random_string.alb_suffix.result}"
  
  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-alb-logs"
    Environment = var.environment
    Purpose     = "ALB Access Logs"
  })
}

# S3 bucket policy for ALB access logs
resource "aws_s3_bucket_policy" "alb_logs" {
  count  = var.access_logs_bucket == null ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*"
      }
    ]
  })
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "alb_logs" {
  count  = var.access_logs_bucket == null ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
