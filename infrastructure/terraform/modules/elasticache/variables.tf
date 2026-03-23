variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ElastiCache"
  type        = list(string)
}

variable "elasticache_security_group_id" {
  description = "Security group ID for ElastiCache"
  type        = string
}

variable "cache_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_auth_token" {
  description = "AUTH token for Redis"
  type        = string
  sensitive   = true
}
