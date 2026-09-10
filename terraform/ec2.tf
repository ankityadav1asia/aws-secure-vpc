# ============================================================
# Amazon Linux 2023 AMI
# ============================================================

data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ============================================================
# EC2 Launch Template
# ============================================================

resource "aws_launch_template" "app" {
  name = "${var.project_name}-app-template"

  image_id = data.aws_ssm_parameter.amazon_linux_2023.value

  instance_type = "t3.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [
    aws_security_group.app.id
  ]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash

    dnf update -y

    dnf install -y nginx

    systemctl enable nginx
    systemctl start nginx

    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
    <head>
      <title>Ankit Secure VPC</title>
    </head>
    <body>
      <h1>AWS Secure VPC Project</h1>
      <p>Private application server is running.</p>
      <p>Instance: $(hostname)</p>
    </body>
    </html>
    HTML
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-app-server"
      Tier        = "private-app"
      Environment = var.environment
    }
  }

  tags = {
    Name        = "${var.project_name}-app-template"
    Environment = var.environment
  }
}