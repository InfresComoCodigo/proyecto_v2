###################################################################
# VPC ENDPOINT PARA S3 (Gateway Endpoint)
###################################################################
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  
  # Asociar con route tables privadas
  route_table_ids = var.private_route_table_ids
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-s3-endpoint"
    Type = "Gateway"
  })
}

###################################################################
# VPC ENDPOINT PARA CLOUDWATCH LOGS (Interface Endpoint)
###################################################################
resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.security_group_id]
  
  # Configuración de DNS - Disabled para evitar conflictos con endpoints existentes
  private_dns_enabled = false
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-cloudwatch-logs-endpoint"
    Type = "Interface"
  })
}

###################################################################
# VPC ENDPOINT PARA CLOUDWATCH MONITORING (Interface Endpoint)
###################################################################
resource "aws_vpc_endpoint" "cloudwatch_monitoring" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.security_group_id]
  
  # Configuración de DNS - Disabled para evitar conflictos con endpoints existentes
  private_dns_enabled = false
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-cloudwatch-monitoring-endpoint"
    Type = "Interface"
  })
}

###################################################################
# VPC ENDPOINT PARA EC2 (Interface Endpoint)
###################################################################
resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.security_group_id]
  
  # Configuración de DNS - Disabled para evitar conflictos con endpoints existentes
  private_dns_enabled = false
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ec2-endpoint"
    Type = "Interface"
  })
}

###################################################################
# DATA SOURCE PARA OBTENER LA REGIÓN ACTUAL
###################################################################
data "aws_region" "current" {}