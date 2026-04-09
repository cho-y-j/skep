# ECR Module for SKEP Services
# Creates ECR repositories for all microservices and frontend

locals {
  services = [
    "api-gateway",
    "auth-service",
    "document-service",
    "equipment-service",
    "dispatch-service",
    "inspection-service",
    "settlement-service",
    "notification-service",
    "location-service",
    "ocr-service",
    "govapi-service",
    "frontend"
  ]
}

resource "aws_ecr_repository" "services" {
  for_each = toset(local.services)

  name                 = "skep-${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "skep-ecr-${each.value}"
    Environment = var.environment
  }
}

# ECR Lifecycle Policy - Keep only the latest 10 images
resource "aws_ecr_lifecycle_policy" "services" {
  for_each = aws_ecr_repository.services

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Pull-through cache rule for base images (optional but recommended)
resource "aws_ecr_pull_through_cache_rule" "docker_hub" {
  ecr_repository_prefix = "docker"
  upstream_registry_url = "registry-1.docker.io"
}

resource "aws_ecr_pull_through_cache_rule" "ghcr" {
  ecr_repository_prefix = "ghcr"
  upstream_registry_url = "ghcr.io"
}

# ECR Registry Scanning Configuration
resource "aws_ecr_registry_scanning_configuration" "main" {
  scan_type = "ENHANCED"

  rules {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = "WILDCARD"
      filter_type = "WILDCARD_ALL"
    }
  }
}
