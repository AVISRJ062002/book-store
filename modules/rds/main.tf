resource "random_id" "final_snapshot" {
  count       = var.skip_final_snapshot ? 0 : 1
  byte_length = 4
}

# Security group narrowly scopes PostgreSQL access to private app runtimes.
resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-postgres-sg"
  description = "Security group for the bookstore PostgreSQL instance"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow PostgreSQL from approved application security groups"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    description = "Allow return traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres-sg"
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-postgres-subnets"
  subnet_ids = var.db_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres-subnets"
  })
}

# Parameter group forces SSL for PostgreSQL clients.
resource "aws_db_parameter_group" "this" {
  name   = "${var.name_prefix}-postgres-params"
  family = var.parameter_group_family

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres-params"
  })
}

# Single-AZ db.t3.micro is the default low-cost production baseline and can be scaled up later.
resource "aws_db_instance" "this" {
  identifier                          = "${var.name_prefix}-postgres"
  engine                              = "postgres"
  engine_version                      = var.engine_version
  instance_class                      = var.instance_class
  db_name                             = var.db_name
  username                            = var.master_username
  manage_master_user_password         = true
  allocated_storage                   = var.allocated_storage
  max_allocated_storage               = var.max_allocated_storage
  storage_type                        = "gp3"
  storage_encrypted                   = true
  publicly_accessible                 = false
  multi_az                            = var.multi_az
  backup_retention_period             = var.backup_retention_days
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = var.skip_final_snapshot
  final_snapshot_identifier           = var.skip_final_snapshot ? null : "${var.name_prefix}-final-${random_id.final_snapshot[0].hex}"
  auto_minor_version_upgrade          = true
  copy_tags_to_snapshot               = true
  apply_immediately                   = false
  iam_database_authentication_enabled = true
  performance_insights_enabled        = false
  db_subnet_group_name                = aws_db_subnet_group.this.name
  vpc_security_group_ids              = [aws_security_group.this.id]
  parameter_group_name                = aws_db_parameter_group.this.name

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-postgres"
  })
}
