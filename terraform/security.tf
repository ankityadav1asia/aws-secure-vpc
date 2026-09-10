# ============================================================
# Application Load Balancer Security Group
# ============================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for the public Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Tier        = "public"
    Environment = var.environment
  }
}

# ============================================================
# Application Server Security Group
# ============================================================

resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for private application servers"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP only from the Application Load Balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound traffic through NAT"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-app-sg"
    Tier        = "private-app"
    Environment = var.environment
  }
}

# ============================================================
# Database Security Group
# ============================================================

resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for the private database tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL only from application servers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow required outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-db-sg"
    Tier        = "private-db"
    Environment = var.environment
  }
}

# ============================================================
# Quarantine Security Group
# ============================================================
#
# This SG is used by the automated incident-response Lambda.
# An EC2 instance placed into this SG loses normal network
# access until the incident is investigated.
#

resource "aws_security_group" "quarantine" {
  name        = "${var.project_name}-quarantine-sg"
  description = "Deny-all security group for compromised EC2 instances"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-quarantine-sg"
    Purpose     = "Incident Response"
    Environment = var.environment
  }
}