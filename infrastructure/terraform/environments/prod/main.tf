terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "skep-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "terraform-locks-prod"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "SKEP"
      Environment = var.environment
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get ACM certificate
data "aws_acm_certificate" "main" {
  domain   = "skep.on1.kr"
  statuses = ["ISSUED"]
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  environment = var.environment
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  environment = var.environment
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  environment             = var.environment
  private_subnet_ids      = module.vpc.private_subnet_ids
  rds_security_group_id   = module.vpc.rds_security_group_id
  db_master_password      = var.db_master_password
  db_instance_class       = var.db_instance_class
}

# ElastiCache Module
module "elasticache" {
  source = "../../modules/elasticache"

  environment                   = var.environment
  private_subnet_ids            = module.vpc.private_subnet_ids
  elasticache_security_group_id = module.vpc.elasticache_security_group_id
  cache_node_type               = var.cache_node_type
  redis_auth_token              = var.redis_auth_token
}

# ALB Module
module "alb" {
  source = "../../modules/alb"

  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  alb_security_group_id  = module.vpc.alb_security_group_id
  acm_certificate_arn    = data.aws_acm_certificate.main.arn
}

# ECS Module
module "ecs" {
  source = "../../modules/ecs"

  environment                  = var.environment
  aws_region                   = var.aws_region
  private_subnet_ids           = module.vpc.private_subnet_ids
  ecs_security_group_id        = module.vpc.ecs_security_group_id
  ecr_repository_urls          = module.ecr.repository_urls
  db_endpoint                  = module.rds.cluster_endpoint
  redis_endpoint               = module.elasticache.redis_endpoint
  api_gateway_target_group_arn = module.alb.api_gateway_target_group_arn
  frontend_target_group_arn    = module.alb.frontend_target_group_arn
}

# S3 Module
module "s3" {
  source = "../../modules/s3"

  environment       = var.environment
  ecs_task_role_arn = module.ecs.ecs_task_role_arn
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "alb_target_health" {
  alarm_name          = "skep-alb-unhealthy-targets-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = module.alb.api_gateway_target_group_arn
    LoadBalancer = module.alb.alb_arn
  }

  tags = {
    Name        = "skep-alb-unhealthy-targets-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "skep-rds-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = module.rds.cluster_id
  }

  tags = {
    Name        = "skep-rds-high-cpu-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "skep-redis-high-cpu-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    ReplicationGroupId = "skep-redis-${var.environment}"
  }

  tags = {
    Name        = "skep-redis-high-cpu-${var.environment}"
    Environment = var.environment
  }
}

# Outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "rds_endpoint" {
  value = module.rds.cluster_endpoint
}

output "redis_endpoint" {
  value = module.elasticache.redis_endpoint
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}
