# Security Group para Application Load Balancer
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  description = "Security group for Application Load Balancer with restricted access"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
    Purpose     = "ALB"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Reglas de entrada separadas para mejor control
resource "aws_security_group_rule" "alb_https_ingress" {
  type              = "ingress"
  description       = "HTTPS from internet for secure web traffic"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

# Reglas de salida restringidas
resource "aws_security_group_rule" "alb_http_egress" {
  type              = "egress"
  description       = "HTTP to private subnets for backend communication"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.private_subnet_cidrs
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_https_egress" {
  type              = "egress"
  description       = "HTTPS to private subnets for secure backend communication"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.private_subnet_cidrs
  security_group_id = aws_security_group.alb.id
}