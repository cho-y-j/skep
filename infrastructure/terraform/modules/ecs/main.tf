# ECS Module for SKEP Microservices

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "skep-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "skep-cluster-${var.environment}"
    Environment = var.environment
  }
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }

  default_capacity_provider_strategy {
    weight            = 0
    capacity_provider = "FARGATE_SPOT"
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/skep-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "skep-ecs-logs-${var.environment}"
    Environment = var.environment
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "skep-ecs-task-execution-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "skep-ecs-task-execution-role-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow execution role to access ECR and CloudWatch
resource "aws_iam_role_policy" "ecs_task_execution_role_ecr_policy" {
  name = "skep-ecs-task-execution-ecr-policy-${var.environment}"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.ecs.arn}:*"
      }
    ]
  })
}

# IAM Role for ECS Task (application permissions)
resource "aws_iam_role" "ecs_task_role" {
  name = "skep-ecs-task-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "skep-ecs-task-role-${var.environment}"
    Environment = var.environment
  }
}

# Allow task role to access S3
resource "aws_iam_role_policy" "ecs_task_role_s3_policy" {
  name = "skep-ecs-task-role-s3-policy-${var.environment}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::skep-documents-${var.environment}-*",
          "arn:aws:s3:::skep-documents-${var.environment}-*/*",
          "arn:aws:s3:::skep-assets-${var.environment}-*",
          "arn:aws:s3:::skep-assets-${var.environment}-*/*"
        ]
      }
    ]
  })
}

# Allow task role to access Parameter Store
resource "aws_iam_role_policy" "ecs_task_role_ssm_policy" {
  name = "skep-ecs-task-role-ssm-policy-${var.environment}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/skep/${var.environment}/*"
      }
    ]
  })
}

# Allow task role to use KMS
resource "aws_iam_role_policy" "ecs_task_role_kms_policy" {
  name = "skep-ecs-task-role-kms-policy-${var.environment}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = [
              "ssm.${var.aws_region}.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

# Allow task role to send emails via SES
resource "aws_iam_role_policy" "ecs_task_role_ses_policy" {
  name = "skep-ecs-task-role-ses-policy-${var.environment}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# ECS Task Definitions - API Gateway
resource "aws_ecs_task_definition" "api_gateway" {
  family                   = "skep-api-gateway-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.environment == "prod" ? "512" : "256"
  memory                   = var.environment == "prod" ? "1024" : "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "api-gateway"
      image     = "${var.ecr_repository_urls["api-gateway"]}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "api-gateway"
        }
      }
      environment = [
        {
          name  = "SPRING_PROFILES_ACTIVE"
          value = var.environment
        },
        {
          name  = "SPRING_DATASOURCE_URL"
          value = "jdbc:postgresql://${var.db_endpoint}:5432/skep"
        },
        {
          name  = "REDIS_HOST"
          value = var.redis_endpoint
        },
        {
          name  = "REDIS_PORT"
          value = "6379"
        }
      ]
      secrets = [
        {
          name      = "SPRING_DATASOURCE_USERNAME"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/skep/${var.environment}/db/username"
        },
        {
          name      = "SPRING_DATASOURCE_PASSWORD"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/skep/${var.environment}/db/password"
        },
        {
          name      = "REDIS_PASSWORD"
          valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/skep/${var.environment}/redis/auth_token"
        }
      ]
    }
  ])

  tags = {
    Name        = "skep-api-gateway-task-${var.environment}"
    Environment = var.environment
  }
}

# ECS Task Definition - Frontend
resource "aws_ecs_task_definition" "frontend" {
  family                   = "skep-frontend-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${var.ecr_repository_urls["frontend"]}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }
      environment = [
        {
          name  = "API_BASE_URL"
          value = "https://skep.on1.kr/api"
        }
      ]
    }
  ])

  tags = {
    Name        = "skep-frontend-task-${var.environment}"
    Environment = var.environment
  }
}

# ECS Service - API Gateway
resource "aws_ecs_service" "api_gateway" {
  name            = "skep-api-gateway-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api_gateway.arn
  desired_count   = var.environment == "prod" ? 2 : 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.api_gateway_target_group_arn
    container_name   = "api-gateway"
    container_port   = 8080
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  depends_on = [aws_iam_role.ecs_task_execution_role]

  tags = {
    Name        = "skep-api-gateway-service-${var.environment}"
    Environment = var.environment
  }
}

# ECS Service - Frontend
resource "aws_ecs_service" "frontend" {
  name            = "skep-frontend-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.environment == "prod" ? 2 : 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.frontend_target_group_arn
    container_name   = "frontend"
    container_port   = 80
  }

  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }

  depends_on = [aws_iam_role.ecs_task_execution_role]

  tags = {
    Name        = "skep-frontend-service-${var.environment}"
    Environment = var.environment
  }
}

# Auto Scaling Target - API Gateway (prod only)
resource "aws_appautoscaling_target" "api_gateway_asg" {
  count = var.environment == "prod" ? 1 : 0

  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api_gateway.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_gateway_cpu" {
  count = var.environment == "prod" ? 1 : 0

  policy_name            = "api-gateway-cpu-autoscaling"
  policy_type            = "TargetTrackingScaling"
  resource_id            = aws_appautoscaling_target.api_gateway_asg[0].resource_id
  scalable_dimension     = aws_appautoscaling_target.api_gateway_asg[0].scalable_dimension
  service_namespace      = aws_appautoscaling_target.api_gateway_asg[0].service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_down_cooldown = 300
    scale_up_cooldown   = 60
  }
}

resource "aws_appautoscaling_policy" "api_gateway_memory" {
  count = var.environment == "prod" ? 1 : 0

  policy_name            = "api-gateway-memory-autoscaling"
  policy_type            = "TargetTrackingScaling"
  resource_id            = aws_appautoscaling_target.api_gateway_asg[0].resource_id
  scalable_dimension     = aws_appautoscaling_target.api_gateway_asg[0].scalable_dimension
  service_namespace      = aws_appautoscaling_target.api_gateway_asg[0].service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 80.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    scale_down_cooldown = 300
    scale_up_cooldown   = 60
  }
}

# Auto Scaling Target - Frontend (prod only)
resource "aws_appautoscaling_target" "frontend_asg" {
  count = var.environment == "prod" ? 1 : 0

  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.frontend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "frontend_cpu" {
  count = var.environment == "prod" ? 1 : 0

  policy_name            = "frontend-cpu-autoscaling"
  policy_type            = "TargetTrackingScaling"
  resource_id            = aws_appautoscaling_target.frontend_asg[0].resource_id
  scalable_dimension     = aws_appautoscaling_target.frontend_asg[0].scalable_dimension
  service_namespace      = aws_appautoscaling_target.frontend_asg[0].service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_down_cooldown = 300
    scale_up_cooldown   = 60
  }
}

data "aws_caller_identity" "current" {}
