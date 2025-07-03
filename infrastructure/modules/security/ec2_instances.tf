# Security Group para instancias EC2
resource "aws_security_group" "ec2_instances" {
  name_prefix = "${var.project_name}-ec2-"
  description = "Security group for EC2 instances in Auto Scaling Group with restricted access"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name        = "${var.project_name}-ec2-instances-sg"
    Environment = var.environment
    Purpose     = "EC2 Instances"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Reglas de entrada específicas y seguras
resource "aws_security_group_rule" "ec2_http_from_alb" {
  type                     = "ingress"
  description              = "HTTP from ALB security group for web traffic routing"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ec2_instances.id
}

resource "aws_security_group_rule" "ec2_https_from_alb" {
  type                     = "ingress"
  description              = "HTTPS from ALB security group for secure web traffic routing"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ec2_instances.id
}

# Reglas de salida específicas y controladas
resource "aws_security_group_rule" "ec2_https_egress_vpc_endpoints" {
  type              = "egress"
  description       = "HTTPS to VPC endpoints for AWS service access"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.private_subnet_cidrs
  security_group_id = aws_security_group.ec2_instances.id
}

resource "aws_security_group_rule" "ec2_mysql_egress" {
  type              = "egress"
  description       = "MySQL to RDS in private subnets for database connectivity"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = var.private_subnet_cidrs
  security_group_id = aws_security_group.ec2_instances.id
}