# ElastiCache Module for SKEP Redis Cluster

resource "aws_elasticache_subnet_group" "main" {
  name       = "skep-elasticache-subnet-group-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "skep-elasticache-subnet-group-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_description = "SKEP Redis Cluster"
  engine                        = "redis"
  engine_version                = "7.0"
  node_type                     = var.cache_node_type
  num_cache_clusters            = var.environment == "prod" ? 3 : 2
  automatic_failover_enabled    = var.environment == "prod" ? true : false
  multi_az_enabled              = var.environment == "prod" ? true : false

  replication_group_id       = "skep-redis-${var.environment}"
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = [var.elasticache_security_group_id]
  parameter_group_name       = aws_elasticache_parameter_group.main.name
  port                       = 6379
  parameter_group_family     = "redis7"
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token

  automatic_minor_version_upgrade = true
  backup_retention_limit          = 7
  snapshot_retention_limit        = 7
  snapshot_window                 = "03:00-05:00"
  maintenance_window              = "sun:05:00-sun:07:00"

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  tags = {
    Name        = "skep-redis-${var.environment}"
    Environment = var.environment
  }

  depends_on = [aws_elasticache_subnet_group.main]
}

resource "aws_elasticache_parameter_group" "main" {
  name        = "skep-redis-params-${var.environment}"
  family      = "redis7"
  description = "Redis parameter group for SKEP"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  tags = {
    Name        = "skep-redis-params-${var.environment}"
    Environment = var.environment
  }
}

# CloudWatch Log Groups for Redis
resource "aws_cloudwatch_log_group" "redis_slow_log" {
  name              = "/aws/elasticache/redis/${var.environment}/slow-log"
  retention_in_days = 7

  tags = {
    Name        = "skep-redis-slow-log-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "redis_engine_log" {
  name              = "/aws/elasticache/redis/${var.environment}/engine-log"
  retention_in_days = 7

  tags = {
    Name        = "skep-redis-engine-log-${var.environment}"
    Environment = var.environment
  }
}

# Store Redis endpoint in Parameter Store
resource "aws_ssm_parameter" "redis_endpoint" {
  name  = "/skep/${var.environment}/redis/endpoint"
  type  = "String"
  value = aws_elasticache_replication_group.main.configuration_endpoint_address

  tags = {
    Name        = "skep-redis-endpoint-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "redis_port" {
  name  = "/skep/${var.environment}/redis/port"
  type  = "String"
  value = "6379"

  tags = {
    Name        = "skep-redis-port-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "redis_auth_token" {
  name  = "/skep/${var.environment}/redis/auth_token"
  type  = "SecureString"
  value = var.redis_auth_token

  tags = {
    Name        = "skep-redis-auth-token-${var.environment}"
    Environment = var.environment
  }
}
