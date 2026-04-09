# S3 Module for SKEP Assets and Documents

# KMS Key for S3 Encryption
resource "aws_kms_key" "s3" {
  description             = "KMS key for SKEP S3 buckets"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = "skep-s3-key-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/skep-s3-${var.environment}"
  target_key_id = aws_kms_key.s3.key_id
}

# Documents Bucket
resource "aws_s3_bucket" "documents" {
  bucket = "skep-documents-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "skep-documents-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["https://skep.on1.kr", "http://localhost:3000", "http://localhost:8080"]
    expose_headers  = ["ETag", "x-amz-version-id"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "documents" {
  bucket = aws_s3_bucket.documents.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSTaskRole"
        Effect = "Allow"
        Principal = {
          AWS = var.ecs_task_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.documents.arn}/*"
      },
      {
        Sid    = "AllowECSTaskRoleList"
        Effect = "Allow"
        Principal = {
          AWS = var.ecs_task_role_arn
        }
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.documents.arn
      }
    ]
  })
}

# Assets Bucket
resource "aws_s3_bucket" "assets" {
  bucket = "skep-assets-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "skep-assets-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://skep.on1.kr", "http://localhost:3000", "http://localhost:8080"]
    expose_headers  = ["ETag"]
    max_age_seconds = 86400
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSTaskRole"
        Effect = "Allow"
        Principal = {
          AWS = var.ecs_task_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.assets.arn}/*"
      },
      {
        Sid    = "AllowECSTaskRoleList"
        Effect = "Allow"
        Principal = {
          AWS = var.ecs_task_role_arn
        }
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.assets.arn
      }
    ]
  })
}

# Store bucket names in Parameter Store
resource "aws_ssm_parameter" "documents_bucket" {
  name  = "/skep/${var.environment}/s3/documents_bucket"
  type  = "String"
  value = aws_s3_bucket.documents.id

  tags = {
    Name        = "skep-documents-bucket-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_ssm_parameter" "assets_bucket" {
  name  = "/skep/${var.environment}/s3/assets_bucket"
  type  = "String"
  value = aws_s3_bucket.assets.id

  tags = {
    Name        = "skep-assets-bucket-${var.environment}"
    Environment = var.environment
  }
}

data "aws_caller_identity" "current" {}
