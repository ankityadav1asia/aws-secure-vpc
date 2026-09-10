# ============================================================
# Application Auto Scaling Group
# ============================================================

resource "aws_autoscaling_group" "app" {
  name = "${var.project_name}-app-asg"

  min_size         = 2
  max_size         = 2
  desired_capacity = 2

  vpc_zone_identifier = [
    aws_subnet.private_app[0].id,
    aws_subnet.private_app[1].id
  ]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  health_check_type = "EC2"

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "private-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}