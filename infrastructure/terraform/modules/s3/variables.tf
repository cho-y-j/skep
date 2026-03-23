variable "environment" {
  description = "Environment name (dev or prod)"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of ECS Task Role"
  type        = string
}
