# RDS Module for SKEP PostgreSQL Database

resource "aws_db_subnet_group" "main" {
  name       = "skep-db-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "skep-db-subnet-group-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_rds_cluster_parameter_group" "main" {
  family      = "postgres16"
  name        = "skep-cluster-params-${var.environment}"
  description = "Cluster parameter group for SKEP"

  # Performance insights enabled
  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_duration"
    value = "1"
  }

  tags = {
    Name        = "skep-cluster-params-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_rds_cluster" "main" {
  cluster_identifier              = "skep-cluster-${var.environment}"
  engine                          = "aurora-postgresql"
  engine_version                  = "16.2"
  database_name                   = "skep"
  master_username                 = "postgres"
  master_password                 = var.db_master_password
  db_subnet_group_name            = aws_db_subnet_group.main.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  vpc_security_group_ids          = [var.rds_security_group_id]

  backup_retention_period      = 7
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"
  copy_tags_to_snapshot        = true
  skip_final_snapshot          = var.environment == "dev" ? true : false
  final_snapshot_identifier    = var.environment == "prod" ? "skep-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null

  enabled_cloudwatch_logs_exports = ["postgresql"]
  enable_http_endpoint            = false
  storage_encrypted               = true
  kms_key_id                      = aws_kms_key.rds.arn

  enable_iam_database_authentication = true

  tags = {
    Name        = "skep-db-cluster-${var.environment}"
    Environment = var.environment
  }

  depends_on = [aws_db_subnet_group.main]
}

# Primary DB Instance
resource "aws_rds_cluster_instance" "primary" {
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.db_instance_class
  engine              = aws_rds_cluster.main.engine
  engine_version      = aws_rds_cluster.main.engine_version

  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  publicly_accessible = false

  tags = {
    Name        = "skep-db-primary-${var.environment}"
    Environment = var.environment
  }
}

# Read Replica (only for prod)
resource "aws_rds_cluster_instance" "replica" {
  count = var.environment == "prod" ? 1 : 0

  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.db_instance_class
  engine              = aws_rds_cluster.main.engine
  engine_version      = aws_rds_cluster.main.engine_version

  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.rds.arn
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  publicly_accessible = false

  tags = {
    Name        = "skep-db-replica-${var.environment}"
    Environment = var.environment
  }
}

# KMS Key for RDS Encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for SKEP RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "skep-rds-key-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/skep-rds-${var.environment}"
  target_key_id = aws_kms_key.rds.key_id
}

# IAM Role for RDS Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "skep-rds-monitoring-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Store RDS credentials in Parameter Store
resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/skep/${var.environment}/db/endpoint"
  type  = "String"
  value = aws_rds_cluster.main.endpoint

  tags = {
    Name        = "skep-db-endpoint-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "db_read_endpoint" {
  name  = "/skep/${var.environment}/db/reader_endpoint"
  type  = "String"
  value = aws_rds_cluster.main.reader_endpoint

  tags = {
    Name        = "skep-db-reader-endpoint-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "db_username" {
  name  = "/skep/${var.environment}/db/username"
  type  = "String"
  value = aws_rds_cluster.main.master_username

  tags = {
    Name        = "skep-db-username-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/skep/${var.environment}/db/password"
  type  = "SecureString"
  value = var.db_master_password

  tags = {
    Name        = "skep-db-password-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/skep/${var.environment}/db/name"
  type  = "String"
  value = aws_rds_cluster.main.database_name

  tags = {
    Name        = "skep-db-name-${var.environment}"
    Environment = var.environment
  }
}
