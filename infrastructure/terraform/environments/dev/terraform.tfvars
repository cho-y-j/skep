aws_region = "ap-northeast-2"
environment = "dev"

# Database Configuration
db_instance_class = "db.t3.medium"

# Cache Configuration
cache_node_type = "cache.t3.micro"

# Note: db_master_password and redis_auth_token should be provided via:
# - Environment variables: TF_VAR_db_master_password, TF_VAR_redis_auth_token
# - -var flag: terraform apply -var="db_master_password=..." -var="redis_auth_token=..."
# - terraform.tfvars.local (not committed to git)
