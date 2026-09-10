resource "aws_db_subnet_group" "main" {
  name = "${var.project_name}-db-subnet-group"
  subnet_ids = [
    aws_subnet.private_db[0].id,
    aws_subnet.private_db[1].id
  ]

  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.environment
  }
}

# ============================================================
# RDS MySQL Database
# ============================================================

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "secureapp"
  username = "dbadmin"

  # Temporary lab password.
  # We will improve secret management later.
  password = "var.db_password"

  port = 3306

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    aws_security_group.db.id
  ]

  publicly_accessible = false

  multi_az = false

  backup_retention_period = 1

  skip_final_snapshot = true

  deletion_protection = false

  auto_minor_version_upgrade = true

  tags = {
    Name        = "${var.project_name}-mysql"
    Tier        = "private-db"
    Environment = var.environment
  }
}