output "cluster_id" {
  description = "RDS Cluster ID"
  value       = aws_rds_cluster.main.id
}

output "cluster_endpoint" {
  description = "RDS Cluster Endpoint"
  value       = aws_rds_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  description = "RDS Cluster Reader Endpoint"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "database_name" {
  description = "Database Name"
  value       = aws_rds_cluster.main.database_name
}

output "master_username" {
  description = "Master Username"
  value       = aws_rds_cluster.main.master_username
  sensitive   = true
}
