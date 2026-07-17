resource "aws_security_group" "db" {
  name_prefix = "${var.name_prefix}-db-"
  description = "Pooled tenant database, reachable only from the app tier"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from the application tier only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "pooled" {
  identifier     = "${var.name_prefix}-pooled"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = "platform"
  username                    = "platform_admin"
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  multi_az               = var.multi_az
  publicly_accessible    = false

  backup_retention_period = 7
  deletion_protection     = var.multi_az
  skip_final_snapshot     = !var.multi_az

  performance_insights_enabled = true
}
