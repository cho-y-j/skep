output "documents_bucket_name" {
  description = "Documents S3 bucket name"
  value       = aws_s3_bucket.documents.id
}

output "documents_bucket_arn" {
  description = "Documents S3 bucket ARN"
  value       = aws_s3_bucket.documents.arn
}

output "assets_bucket_name" {
  description = "Assets S3 bucket name"
  value       = aws_s3_bucket.assets.id
}

output "assets_bucket_arn" {
  description = "Assets S3 bucket ARN"
  value       = aws_s3_bucket.assets.arn
}
