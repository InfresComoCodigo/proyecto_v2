output "asg_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.reservas_asg.name
}

output "launch_template_id" {
  description = "ID del Launch Template"
  value       = aws_launch_template.reservas_lt.id
}