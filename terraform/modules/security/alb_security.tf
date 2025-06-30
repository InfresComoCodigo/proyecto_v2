# Security Group para Application Load Balancer
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # Reglas de entrada - permitir HTTP desde internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Reglas de entrada - permitir HTTPS desde internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }



  # Reglas de salida - permitir HTTP hacia subredes privadas (instancias EC2)
  egress {
    description = "HTTP to private subnets"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  # Reglas de salida - permitir HTTPS hacia subredes privadas (instancias EC2)
  egress {
    description = "HTTPS to private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
    Purpose     = "ALB"
  })

  lifecycle {
    create_before_destroy = true
  }
}