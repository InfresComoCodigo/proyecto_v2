# Security Group para VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.project_name}-vpc-endpoints-"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  # Reglas de entrada - permitir HTTPS desde las subnets privadas
  ingress {
    description = "HTTPS from private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  # Reglas de salida - permitir todo el tráfico saliente
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-vpc-endpoints-sg"
    Environment = var.environment
    Purpose     = "VPC Endpoints"
  })

  lifecycle {
    create_before_destroy = true
  }
}
