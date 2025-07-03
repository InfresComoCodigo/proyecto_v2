# Security Group para VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.project_name}-vpc-endpoints-"
  description = "Security group for VPC endpoints with restricted access"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name        = "${var.project_name}-vpc-endpoints-sg"
    Environment = var.environment
    Purpose     = "VPC Endpoints"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Separate security group rules for better control
resource "aws_security_group_rule" "vpc_endpoints_https_ingress" {
  type              = "ingress"
  description       = "HTTPS from private subnets for VPC endpoint access"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.private_subnet_cidrs
  security_group_id = aws_security_group.vpc_endpoints.id
}

# Restrict egress to specific ports and protocols instead of allowing all
resource "aws_security_group_rule" "vpc_endpoints_https_egress" {
  type              = "egress"
  description       = "HTTPS to AWS services through VPC endpoints"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpc_endpoints.id
}
