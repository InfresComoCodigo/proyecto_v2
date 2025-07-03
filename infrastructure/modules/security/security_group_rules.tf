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
  description              = "Allow ALB to access EC2 instances on port 80 for HTTP traffic"
}

# Regla específica: ALB puede acceder a EC2 en puerto 443
resource "aws_security_group_rule" "alb_to_ec2_https" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_instances.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow ALB to access EC2 instances on port 443 for HTTPS traffic"
}
