# NOTA: Security Group para VPC Link ya no es necesario porque conectamos directamente
# API Gateway con ALB público. Se mantiene comentado para futuras referencias.

# Security Group para API Gateway VPC Link
# resource "aws_security_group" "api_gateway_vpc_link" {
#   name_prefix = "${var.project_name}-api-gateway-vpc-link-"
#   description = "Security group for API Gateway VPC Link"
#   vpc_id      = var.vpc_id

#   # Reglas de entrada - permitir HTTP desde API Gateway
#   ingress {
#     description = "HTTP from API Gateway"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]  # API Gateway necesita acceso amplio para VPC Link
#   }

#   # Reglas de entrada - permitir HTTPS desde API Gateway
#   ingress {
#     description = "HTTPS from API Gateway"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]  # API Gateway necesita acceso amplio para VPC Link
#   }

#   tags = merge(var.tags, {
#     Name        = "${var.project_name}-api-gateway-vpc-link-sg"
#     Environment = var.environment
#     Purpose     = "API Gateway VPC Link"
#   })

#   lifecycle {
#     create_before_destroy = true
#   }
# }
