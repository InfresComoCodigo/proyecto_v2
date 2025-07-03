###################################################################
# OUTPUTS - Información del módulo compute
###################################################################

# Instancias EC2 fijas - Zone A
output "ec2_zone_a_id" {
  description = "ID de la instancia EC2 fija en zona us-east-1a"
  value       = aws_instance.ec2_zone_a.id
}

output "ec2_zone_a_private_ip" {
  description = "IP privada de la instancia EC2 fija en zona us-east-1a"
  value       = aws_instance.ec2_zone_a.private_ip
}

output "ec2_zone_a_arn" {
  description = "ARN de la instancia EC2 fija en zona us-east-1a"
  value       = aws_instance.ec2_zone_a.arn
}

# Instancias EC2 fijas - Zone B
output "ec2_zone_b_id" {
  description = "ID de la instancia EC2 fija en zona us-east-1b"
  value       = aws_instance.ec2_zone_b.id
}

output "ec2_zone_b_private_ip" {
  description = "IP privada de la instancia EC2 fija en zona us-east-1b"
  value       = aws_instance.ec2_zone_b.private_ip
}

output "ec2_zone_b_arn" {
  description = "ARN de la instancia EC2 fija en zona us-east-1b"
  value       = aws_instance.ec2_zone_b.arn
}

# Auto Scaling Group outputs
output "autoscaling_group_name" {
  description = "Nombre del Auto Scaling Group"
  value       = aws_autoscaling_group.asg.name
}

output "autoscaling_group_arn" {
  description = "ARN del Auto Scaling Group"
  value       = aws_autoscaling_group.asg.arn
}

output "autoscaling_group_id" {
  description = "ID del Auto Scaling Group"
  value       = aws_autoscaling_group.asg.id
}

# Launch Template outputs
output "launch_template_id" {
  description = "ID del Launch Template del ASG"
  value       = aws_launch_template.asg_launch_template.id
}

output "launch_template_version" {
  description = "Versión del Launch Template del ASG"
  value       = aws_launch_template.asg_launch_template.latest_version
}

output "launch_template_name" {
  description = "Nombre del Launch Template del ASG"
  value       = aws_launch_template.asg_launch_template.name
}

# Scaling Policies outputs
output "scale_up_policy_arn" {
  description = "ARN de la política de escalado hacia arriba"
  value       = aws_autoscaling_policy.scale_up.arn
}

output "scale_down_policy_arn" {
  description = "ARN de la política de escalado hacia abajo"
  value       = aws_autoscaling_policy.scale_down.arn
}

# CloudWatch Alarms outputs
output "cpu_high_alarm_name" {
  description = "Nombre de la alarma de CPU alta"
  value       = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
}

output "cpu_low_alarm_name" {
  description = "Nombre de la alarma de CPU baja"
  value       = aws_cloudwatch_metric_alarm.cpu_low.alarm_name
}

# Configuración combinada de instancias
output "instances_configuration" {
  description = "Configuración completa de todas las instancias"
  value = {
    fixed_instances = {
      instance_type = var.instance_type
      ami_id        = var.ami_id
      zone_a_subnet = var.subnet_ids[0]
      zone_b_subnet = var.subnet_ids[1]
    }
    auto_scaling = {
      min_additional_instances = var.min_size
      max_additional_instances = var.max_size
      current_additional_instances = var.desired_capacity
    }
    total_capacity = {
      minimum_total = 2 + var.min_size
      maximum_total = 2 + var.max_size
      current_total = 2 + var.desired_capacity
    }
  }
}

# Todas las instancias fijas
output "all_fixed_instance_ids" {
  description = "Lista de todos los IDs de instancias fijas"
  value       = [aws_instance.ec2_zone_a.id, aws_instance.ec2_zone_b.id]
}

output "all_fixed_private_ips" {
  description = "Lista de todas las IPs privadas de las instancias fijas"
  value       = [aws_instance.ec2_zone_a.private_ip, aws_instance.ec2_zone_b.private_ip]
}

# Capacity information
output "capacity_configuration" {
  description = "Configuración de capacidad del ASG"
  value = {
    min_size         = aws_autoscaling_group.asg.min_size
    max_size         = aws_autoscaling_group.asg.max_size
    desired_capacity = aws_autoscaling_group.asg.desired_capacity
  }
}
