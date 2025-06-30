###################################################################
# OUTPUTS - Información del ALB
###################################################################

output "alb_arn" {
  description = "ARN del Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name del ALB"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID del ALB"
  value       = aws_lb.main.zone_id
}

output "alb_security_group_id" {
  description = "ID del security group del ALB"
  value       = var.security_group_id
}

output "target_group_arn" {
  description = "ARN del target group"
  value       = aws_lb_target_group.ec2_targets.arn
}

output "target_group_name" {
  description = "Nombre del target group"
  value       = aws_lb_target_group.ec2_targets.name
}

output "listener_arn" {
  description = "ARN del listener"
  value       = aws_lb_listener.main.arn
}

output "alb_url" {
  description = "URL completa del ALB"
  value       = "http://${aws_lb.main.dns_name}"
}