# ALB Module for SKEP Load Balancing

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "skep-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false
  enable_http2               = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name        = "skep-alb-${var.environment}"
    Environment = var.environment
  }
}

# Target Group - API Gateway
resource "aws_lb_target_group" "api_gateway" {
  name        = "skep-api-gateway-${var.environment}"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/actuator/health"
    matcher             = "200"
    port                = "8080"
  }

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400
  }

  tags = {
    Name        = "skep-api-gateway-tg-${var.environment}"
    Environment = var.environment
  }
}

# Target Group - Frontend
resource "aws_lb_target_group" "frontend" {
  name        = "skep-frontend-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    matcher             = "200-299"
    port                = "80"
  }

  tags = {
    Name        = "skep-frontend-tg-${var.environment}"
    Environment = var.environment
  }
}

# HTTP Listener (redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# HTTPS Listener Rule - API Gateway path routing
resource "aws_lb_listener_rule" "api_gateway" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_gateway.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# Store ALB DNS in Parameter Store
resource "aws_ssm_parameter" "alb_dns" {
  name  = "/skep/${var.environment}/alb/dns_name"
  type  = "String"
  value = aws_lb.main.dns_name

  tags = {
    Name        = "skep-alb-dns-${var.environment}"
    Environment = var.environment
  }
}
