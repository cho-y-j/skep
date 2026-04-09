output "repository_urls" {
  description = "ECR repository URLs"
  value = {
    for service, repo in aws_ecr_repository.services :
    service => repo.repository_url
  }
}

output "registry_id" {
  description = "AWS Account ID (ECR Registry ID)"
  value       = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}
