# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = "raisetech-tf-db-subnet-group"
  description = "DB Subnet Group for RaiseTech"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = "raisetech-tf-db-subnet-group"
  }
}

# RDS MySQL
resource "aws_db_instance" "main" {
  identifier = var.rds_instance_identifier

  engine         = "mysql"
  instance_class = "db.t3.micro"

  db_name  = "awsstudy"
  port     = 3306
  username = var.db_username

  # Secrets Manager
  manage_master_user_password = true

  # Storage
  allocated_storage = 20
  storage_encrypted = true

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible    = false
  multi_az               = false

  # Backup and deletion
  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true

  # CloudWatch Logs
  enabled_cloudwatch_logs_exports = ["error"]

  tags = {
    Name = "raisetech-tf-rds"
  }
}
