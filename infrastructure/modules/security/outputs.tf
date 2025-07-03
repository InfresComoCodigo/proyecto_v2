# Outputs para el módulo security

output "vpc_endpoints_sg_id" {
  description = "ID del security group para VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

output "vpc_endpoints_sg_arn" {
  description = "ARN del security group para VPC endpoints"
  value       = aws_security_group.vpc_endpoints.arn
}

output "ec2_instances_sg_id" {
  description = "ID del security group para instancias EC2"
  value       = aws_security_group.ec2_instances.id
}

output "ec2_instances_sg_arn" {
  description = "ARN del security group para instancias EC2"
  value       = aws_security_group.ec2_instances.arn
}

output "alb_sg_id" {
  description = "ID del security group para ALB"
  value       = aws_security_group.alb.id
}

output "alb_sg_arn" {
  description = "ARN del security group para ALB"
  value       = aws_security_group.alb.arn
}

# NOTA: Outputs del VPC Link Security Group comentados ya que no se usa más VPC Link
# output "api_gateway_vpc_link_sg_id" {
#   description = "ID del security group para API Gateway VPC Link"
#   value       = aws_security_group.api_gateway_vpc_link.id
# }

# output "api_gateway_vpc_link_sg_arn" {
#   description = "ARN del security group para API Gateway VPC Link"
#   value       = aws_security_group.api_gateway_vpc_link.arn
# }