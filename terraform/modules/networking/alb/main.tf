###################################################################
# RANDOM SUFFIX FOR UNIQUE NAMING
###################################################################

# Random suffix for unique resource naming
resource "random_string" "alb_suffix" {
  length  = 6
  special = false
  upper   = false
}

###################################################################
# APPLICATION LOAD BALANCER
###################################################################

resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb-${random_string.alb_suffix.result}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Type        = "ApplicationLoadBalancer"
  })
}

###################################################################
# TARGET GROUP
###################################################################

resource "aws_lb_target_group" "ec2_targets" {
  name     = "${var.project_name}-${var.environment}-tg-${random_string.alb_suffix.result}"
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-target-group"
    Environment = var.environment
  })
}

###################################################################
# TARGET GROUP ATTACHMENTS - Instancias fijas (opcional)
###################################################################

resource "aws_lb_target_group_attachment" "ec2_targets" {
  count            = length(var.target_instance_ids)
  target_group_arn = aws_lb_target_group.ec2_targets.arn
  target_id        = var.target_instance_ids[count.index]
  port             = var.target_port
}

###################################################################
# LISTENER
###################################################################

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_targets.arn
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-listener"
    Environment = var.environment
  })
}
