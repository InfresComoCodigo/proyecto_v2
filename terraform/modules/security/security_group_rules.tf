# Reglas adicionales de Security Group para referencias cruzadas
# Este archivo maneja las referencias entre security groups sin crear dependencias circulares

###################################################################
# REGLAS ADICIONALES PARA ALB → EC2
###################################################################

# Regla específica: ALB puede acceder a EC2 en puerto 80
resource "aws_security_group_rule" "alb_to_ec2_http" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_instances.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow ALB to access EC2 instances on port 80"
}

# Regla específica: ALB puede acceder a EC2 en puerto 443
resource "aws_security_group_rule" "alb_to_ec2_https" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_instances.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow ALB to access EC2 instances on port 443"
}

###################################################################
# REGLAS ADICIONALES PARA EC2 ← ALB
###################################################################

# Regla específica: EC2 puede recibir tráfico del ALB en puerto 80
resource "aws_security_group_rule" "ec2_from_alb_http" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ec2_instances.id
  description              = "Allow EC2 to receive HTTP traffic from ALB"
}

# Regla específica: EC2 puede recibir tráfico del ALB en puerto 443
resource "aws_security_group_rule" "ec2_from_alb_https" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ec2_instances.id
  description              = "Allow EC2 to receive HTTPS traffic from ALB"
}

###################################################################
# REGLAS ADICIONALES PARA API GATEWAY VPC LINK ↔ ALB
# NOTA: Estas reglas están comentadas porque ahora usamos conexión directa
# API Gateway → ALB sin VPC Link
###################################################################

# Regla específica: API Gateway VPC Link puede enviar tráfico HTTP al ALB
# resource "aws_security_group_rule" "api_gateway_to_alb_http" {
#   type                     = "egress"
#   from_port                = 80
#   to_port                  = 80
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.alb.id
#   security_group_id        = aws_security_group.api_gateway_vpc_link.id
#   description              = "Allow API Gateway VPC Link to access ALB on port 80"
# }

# Regla específica: API Gateway VPC Link puede enviar tráfico HTTPS al ALB
# resource "aws_security_group_rule" "api_gateway_to_alb_https" {
#   type                     = "egress"
#   from_port                = 443
#   to_port                  = 443
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.alb.id
#   security_group_id        = aws_security_group.api_gateway_vpc_link.id
#   description              = "Allow API Gateway VPC Link to access ALB on port 443"
# }

# Regla específica: ALB puede recibir tráfico HTTP desde API Gateway VPC Link
# resource "aws_security_group_rule" "alb_from_api_gateway_http" {
#   type                     = "ingress"
#   from_port                = 80
#   to_port                  = 80
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.api_gateway_vpc_link.id
#   security_group_id        = aws_security_group.alb.id
#   description              = "Allow ALB to receive HTTP traffic from API Gateway VPC Link"
# }

# Regla específica: ALB puede recibir tráfico HTTPS desde API Gateway VPC Link
# resource "aws_security_group_rule" "alb_from_api_gateway_https" {
#   type                     = "ingress"
#   from_port                = 443
#   to_port                  = 443
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.api_gateway_vpc_link.id
#   security_group_id        = aws_security_group.alb.id
#   description              = "Allow ALB to receive HTTPS traffic from API Gateway VPC Link"
# }
