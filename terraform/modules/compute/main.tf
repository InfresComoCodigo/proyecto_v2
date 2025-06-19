resource "aws_launch_template" "reservas_lt" {
  name_prefix   = "reservas-lt-"
  image_id      = var.ami_id  # Usar la variable del AMI
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [var.ec2_sg_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.volume_size
      volume_type = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.env}-reservas-instance"
    }
  }

  user_data = var.enable_user_data ? base64encode(templatefile("${path.module}/user_data.sh", {
    env = var.env
  })) : null
}

resource "aws_autoscaling_group" "reservas_asg" {
  name_prefix         = "reservas-asg-"
  vpc_zone_identifier = var.private_subnets
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size

  launch_template {
    id      = aws_launch_template.reservas_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.env}-reservas-asg"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Perfil de IAM para las instancias EC2
resource "aws_iam_role" "ec2_role" {
  name_prefix = "ec2-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "ec2-profile-"
  role        = aws_iam_role.ec2_role.name
}