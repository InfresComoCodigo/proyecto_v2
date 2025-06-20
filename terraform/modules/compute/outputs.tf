output "asg_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.reservas_asg.name
}

output "launch_template_id" {
  description = "ID del Launch Template"
  value       = aws_launch_template.reservas_lt.id
}

output "alb_dns_name" {
  description = "DNS del Application Load Balancer"
  value       = aws_lb.app_lb.dns_name
}

output "target_group_arn" {
  description = "ARN del Target Group"
  value       = aws_lb_target_group.app_tg.arn
}