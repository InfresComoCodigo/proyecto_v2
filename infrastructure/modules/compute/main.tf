###################################################################
# INSTANCIA EC2 - ZONA us-east-1a (Subnet 10.0.101.0/24)
###################################################################

resource "aws_instance" "ec2_zone_a" {
    ami                    = var.ami_id
    instance_type         = var.instance_type
    key_name              = var.key_name != null && var.key_name != "" ? var.key_name : null
    subnet_id             = var.subnet_ids[0]  # Primera subnet privada (10.0.101.0/24)
    vpc_security_group_ids = [var.security_group_id]
    
    # Script de inicialización
    user_data = fileexists(var.user_data_file) ? file(var.user_data_file) : null
    
    # Monitoreo detallado
    monitoring = var.enable_monitoring
    
    # Tags
    tags = merge(var.tags, {
        Name        = "${var.project_name}-${var.environment}-ec2-zone-a"
        Environment = var.environment
        Zone        = "us-east-1a"
        Subnet      = "10.0.101.0/24"
        Type        = "Fixed"
    })
}

###################################################################
# INSTANCIA EC2 - ZONA us-east-1b (Subnet 10.0.102.0/24)
###################################################################

resource "aws_instance" "ec2_zone_b" {
    ami                    = var.ami_id
    instance_type         = var.instance_type
    key_name              = var.key_name != null && var.key_name != "" ? var.key_name : null
    subnet_id             = var.subnet_ids[1]  # Segunda subnet privada (10.0.102.0/24)
    vpc_security_group_ids = [var.security_group_id]
    
    # Script de inicialización
    user_data = fileexists(var.user_data_file) ? file(var.user_data_file) : null
    
    # Monitoreo detallado
    monitoring = var.enable_monitoring
    
    # Tags
    tags = merge(var.tags, {
        Name        = "${var.project_name}-${var.environment}-ec2-zone-b"
        Environment = var.environment
        Zone        = "us-east-1b"
        Subnet      = "10.0.102.0/24"
        Type        = "Fixed"
    })
}

###################################################################
# LAUNCH TEMPLATE - Para instancias de Auto Scaling
###################################################################

resource "aws_launch_template" "asg_launch_template" {
    name_prefix   = "${var.project_name}-${var.environment}-asg-"
    image_id      = var.ami_id
    instance_type = var.instance_type

    # Key pair solo si está especificado
    key_name = var.key_name != null && var.key_name != "" ? var.key_name : null

    # Cifrado de user data (no debe contener secretos hardcodeados)
    user_data = var.user_data_file != null && var.user_data_file != "" ? (
        fileexists(var.user_data_file) ? filebase64(var.user_data_file) : null
    ) : null

    # Configuración de metadatos IMDSv2 para cumplir CKV_AWS_341
    metadata_options {
        http_tokens                 = "required"  # Forzar IMDSv2
        http_put_response_hop_limit = 1           # Límite de 1 hop para cumplir CKV_AWS_341
        http_endpoint               = "enabled"
        http_protocol_ipv6          = "disabled"
        instance_metadata_tags      = "enabled"
    }

    # Configuración de red
    network_interfaces {
        associate_public_ip_address = false  # Sin IP pública para cumplir CKV_AWS_88
        security_groups            = [var.security_group_id]
        delete_on_termination      = true
        device_index               = 0
    }

    # Monitoreo detallado
    monitoring {
        enabled = var.enable_monitoring
    }

    # Configuración de almacenamiento cifrado
    block_device_mappings {
        device_name = "/dev/xvda"
        ebs {
            volume_type           = "gp3"
            volume_size           = 20
            encrypted             = true
            delete_on_termination = true
            kms_key_id           = var.kms_key_id
        }
    }

    # Tags para las instancias de ASG
    tag_specifications {
        resource_type = "instance"
        tags = merge(var.tags, {
            Name        = "${var.project_name}-${var.environment}-asg-instance"
            Environment = var.environment
            LaunchedBy  = "AutoScaling"
            Type        = "AutoScaled"
        })
    }

    tag_specifications {
        resource_type = "volume"
        tags = merge(var.tags, {
            Name        = "${var.project_name}-${var.environment}-asg-volume"
            Environment = var.environment
        })
    }

    # Tags para el launch template
    tags = merge(var.tags, {
        Name        = "${var.project_name}-${var.environment}-asg-launch-template"
        Environment = var.environment
    })
}

###################################################################
# AUTO SCALING GROUP - Escalado adicional (mín: 0, máx: 2)
###################################################################

resource "aws_autoscaling_group" "asg" {
    name                = "${var.project_name}-${var.environment}-asg"
    vpc_zone_identifier = var.subnet_ids
    
    # Configuración de capacidad: 
    # - Instancias fijas: 2 (una en cada zona)
    # - ASG adicional: 0-2 instancias (total máximo: 4)
    min_size         = var.min_size
    max_size         = var.max_size
    desired_capacity = var.desired_capacity

    # Launch Template (obligatorio para cumplir CKV_AWS_315)
    launch_template {
        id      = aws_launch_template.asg_launch_template.id
        version = "$Latest"
    }
    
    # Target Group del ALB - Las instancias del ASG se registrarán automáticamente
    target_group_arns = var.target_group_arn != null ? [var.target_group_arn] : []
    
    # Health checks
    health_check_type         = var.target_group_arn != null ? "ELB" : "EC2"
    health_check_grace_period = var.health_check_grace_period
    
    # Configuración de reemplazo y timeouts
    force_delete              = true
    wait_for_capacity_timeout = "10m"
    
    # Tags para el ASG (obligatorios para cumplir CKV_AWS_153)
    tag {
        key                 = "Name"
        value               = "${var.project_name}-${var.environment}-asg"
        propagate_at_launch = true  # Cambiar a true para cumplir CKV_AWS_153
    }
    
    tag {
        key                 = "Environment"
        value               = var.environment
        propagate_at_launch = true
    }
    
    tag {
        key                 = "Project"
        value               = var.project_name
        propagate_at_launch = true
    }

    tag {
        key                 = "Type"
        value               = "AutoScaled"
        propagate_at_launch = true
    }

    # Aplicar tags adicionales
    dynamic "tag" {
        for_each = var.tags
        content {
            key                 = tag.key
            value               = tag.value
            propagate_at_launch = true
        }
    }
}

###################################################################
# POLÍTICAS DE ESCALADO
###################################################################

# Política de escalado hacia arriba (scale up)
resource "aws_autoscaling_policy" "scale_up" {
    name                   = "${var.project_name}-${var.environment}-scale-up"
    scaling_adjustment     = 1
    adjustment_type        = "ChangeInCapacity"
    cooldown              = 300
    autoscaling_group_name = aws_autoscaling_group.asg.name
    policy_type           = "SimpleScaling"
}

# Política de escalado hacia abajo (scale down)
resource "aws_autoscaling_policy" "scale_down" {
    name                   = "${var.project_name}-${var.environment}-scale-down"
    scaling_adjustment     = -1
    adjustment_type        = "ChangeInCapacity"
    cooldown              = 300
    autoscaling_group_name = aws_autoscaling_group.asg.name
    policy_type           = "SimpleScaling"
}

###################################################################
# CLOUDWATCH ALARMS - Monitoreo y alertas
###################################################################

# Alarma CloudWatch para CPU alta (escalar hacia arriba)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
    alarm_name          = "${var.project_name}-${var.environment}-cpu-high"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = "2"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = "120"
    statistic           = "Average"
    threshold           = var.scale_up_threshold
    alarm_description   = "Triggers scale up when CPU utilization is high"
    alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
    actions_enabled     = true

    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.asg.name
    }

    tags = merge(var.tags, {
        Name        = "${var.project_name}-${var.environment}-cpu-high-alarm"
        Environment = var.environment
    })
}

# Alarma CloudWatch para CPU baja (escalar hacia abajo)
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
    alarm_name          = "${var.project_name}-${var.environment}-cpu-low"
    comparison_operator = "LessThanThreshold"
    evaluation_periods  = "2"
    metric_name         = "CPUUtilization"
    namespace           = "AWS/EC2"
    period              = "120"
    statistic           = "Average"
    threshold           = var.scale_down_threshold
    alarm_description   = "Triggers scale down when CPU utilization is low"
    alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
    actions_enabled     = true

    dimensions = {
        AutoScalingGroupName = aws_autoscaling_group.asg.name
    }

    tags = merge(var.tags, {
        Name        = "${var.project_name}-${var.environment}-cpu-low-alarm"
        Environment = var.environment
    })
}

