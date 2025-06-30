# Security Group para instancias EC2
resource "aws_security_group" "ec2_instances" {
  name_prefix = "${var.project_name}-ec2-"
  description = "Security group for EC2 instances in Auto Scaling Group"
  vpc_id      = var.vpc_id

  # Reglas de entrada - permitir tráfico SSH desde redes privadas (para debugging)
  ingress {
    description = "SSH from private subnets"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  # Reglas de entrada - permitir tráfico HTTP desde cualquier lugar en la VPC
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Toda la VPC
  }

  # Reglas de entrada - permitir tráfico HTTPS desde cualquier lugar en la VPC
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Toda la VPC
  }

  # Reglas de entrada - permitir tráfico HTTP desde subredes públicas (ALB)
  ingress {
    description = "HTTP from public subnets (ALB)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]  # Subredes públicas
  }

  # Reglas de entrada - permitir tráfico HTTPS desde subredes públicas (ALB)
  ingress {
    description = "HTTPS from public subnets (ALB)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]  # Subredes públicas
  }

  # Reglas de salida - permitir HTTPS hacia VPC endpoints
  egress {
    description = "HTTPS to VPC endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  # Reglas de salida - permitir todo el tráfico saliente (temporal)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-ec2-instances-sg"
    Environment = var.environment
    Purpose     = "EC2 Instances"
  })

  lifecycle {
    create_before_destroy = true
  }
}