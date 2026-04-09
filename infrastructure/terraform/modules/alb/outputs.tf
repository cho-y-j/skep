output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_lb.main.zone_id
}

output "api_gateway_target_group_arn" {
  description = "API Gateway Target Group ARN"
  value       = aws_lb_target_group.api_gateway.arn
}

output "frontend_target_group_arn" {
  description = "Frontend Target Group ARN"
  value       = aws_lb_target_group.frontend.arn
}
