# SKEP AWS Infrastructure Deployment Guide

This guide provides comprehensive instructions for setting up the SKEP AWS infrastructure using Terraform and deploying applications via GitHub Actions.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Terraform State Management](#terraform-state-management)
4. [Deploying Infrastructure](#deploying-infrastructure)
5. [GitHub Actions Setup](#github-actions-setup)
6. [Application Deployment](#application-deployment)
7. [Monitoring and Operations](#monitoring-and-operations)

## Prerequisites

### Tools Required
- Terraform >= 1.5.0
- AWS CLI >= 2.13
- Docker >= 20.10
- Git >= 2.40
- GitHub CLI >= 2.0

### AWS Account Requirements
- AWS Account with appropriate permissions
- IAM user with programmatic access (Access Key ID and Secret Access Key)
- ACM certificate for domain `skep.on1.kr` already created in ap-northeast-2 region

### GitHub Requirements
- GitHub repository at https://github.com/cho-y-j/skep
- GitHub Actions enabled

## Initial Setup

### Step 1: Clone Repository
```bash
git clone https://github.com/cho-y-j/skep.git
cd skep
```

### Step 2: Set Up AWS Credentials

Option A: Using AWS CLI (recommended for local development)
```bash
aws configure
# Enter: Access Key ID
# Enter: Secret Access Key
# Enter: Default region = ap-northeast-2
# Enter: Default output = json
```

Option B: Using Environment Variables
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="ap-northeast-2"
```

### Step 3: Create Terraform State Buckets

Create S3 buckets for storing Terraform state (do this once, manually):

```bash
# For dev environment
aws s3 mb s3://skep-terraform-state-dev-$(aws sts get-caller-identity --query Account --output text) \
  --region ap-northeast-2

# For prod environment
aws s3 mb s3://skep-terraform-state-prod-$(aws sts get-caller-identity --query Account --output text) \
  --region ap-northeast-2

# Enable versioning for both buckets
aws s3api put-bucket-versioning \
  --bucket skep-terraform-state-dev-$(aws sts get-caller-identity --query Account --output text) \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-versioning \
  --bucket skep-terraform-state-prod-$(aws sts get-caller-identity --query Account --output text) \
  --versioning-configuration Status=Enabled

# Enable encryption for both buckets
aws s3api put-bucket-encryption \
  --bucket skep-terraform-state-dev-$(aws sts get-caller-identity --query Account --output text) \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

aws s3api put-bucket-encryption \
  --bucket skep-terraform-state-prod-$(aws sts get-caller-identity --query Account --output text) \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'
```

### Step 4: Create DynamoDB Tables for State Locking

```bash
# For dev environment
aws dynamodb create-table \
  --table-name terraform-locks-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ap-northeast-2

# For prod environment
aws dynamodb create-table \
  --table-name terraform-locks-prod \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ap-northeast-2
```

## Terraform State Management

### Backend Configuration
The Terraform backend is configured in `environments/{dev,prod}/main.tf`:

```hcl
backend "s3" {
  bucket         = "skep-terraform-state-{env}"
  key            = "{env}/terraform.tfstate"
  region         = "ap-northeast-2"
  encrypt        = true
  dynamodb_table = "terraform-locks-{env}"
}
```

### Important Notes
- **Never commit `.tfstate` files** to git
- Use S3 backend with encryption and versioning enabled
- DynamoDB table prevents concurrent modifications
- Always use `terraform lock` when modifying infrastructure

## Deploying Infrastructure

### Step 1: Prepare Variables

Create `terraform.tfvars.local` in the environment directory (never commit):

```hcl
# For dev environment: infrastructure/terraform/environments/dev/terraform.tfvars.local
db_master_password = "YourVerySecurePassword123!"
redis_auth_token   = "YourRedisAuthToken456!"
```

### Step 2: Initialize Terraform

```bash
cd infrastructure/terraform/environments/dev

# Initialize Terraform (downloads providers and modules)
terraform init

# Validate configuration
terraform validate
```

### Step 3: Plan Deployment

```bash
terraform plan -out=tfplan

# Review the plan output carefully!
# It shows all resources that will be created, modified, or destroyed
```

### Step 4: Apply Configuration

```bash
# Apply the planned changes
terraform apply tfplan

# Wait for completion (usually 15-20 minutes for first deployment)
```

### Step 5: Verify Deployment

```bash
# Check outputs
terraform output

# Verify resources in AWS
aws ecs list-clusters --region ap-northeast-2
aws rds describe-db-clusters --region ap-northeast-2
aws elasticache describe-replication-groups --region ap-northeast-2
```

### Production Deployment

Repeat the same steps for prod environment:

```bash
cd infrastructure/terraform/environments/prod
terraform init
terraform plan
terraform apply
```

## GitHub Actions Setup

### Step 1: Set Up OIDC for AWS

Create an IAM role for GitHub Actions to assume:

```bash
# Create OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Create IAM role for GitHub Actions
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:cho-y-j/skep:*"
        }
      }
    }
  ]
}
EOF

aws iam create-role \
  --role-name GitHubActionsSkepRole \
  --assume-role-policy-document file://trust-policy.json
```

### Step 2: Create GitHub Secrets

Go to GitHub repository Settings > Secrets and Variables > Actions and add:

```
AWS_ACCOUNT_ID              = your-aws-account-id
AWS_REGION                  = ap-northeast-2
AWS_ROLE_TO_ASSUME          = arn:aws:iam::ACCOUNT_ID:role/GitHubActionsSkepRole
TF_VAR_DB_MASTER_PASSWORD   = your-secure-db-password
TF_VAR_REDIS_AUTH_TOKEN     = your-redis-auth-token
SLACK_WEBHOOK_URL           = https://hooks.slack.com/services/... (optional)
```

### Step 3: Attach IAM Policies

Attach necessary policies to the GitHub Actions role:

```bash
# ECR access
aws iam attach-role-policy \
  --role-name GitHubActionsSkepRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser

# ECS access
aws iam attach-role-policy \
  --role-name GitHubActionsSkepRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess

# Terraform access (attach custom policy)
cat > terraform-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "dynamodb:*",
        "ec2:*",
        "rds:*",
        "elasticache:*",
        "elasticloadbalancing:*",
        "acm:*",
        "iam:*",
        "ssm:*",
        "logs:*",
        "cloudwatch:*",
        "kms:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name GitHubActionsSkepRole \
  --policy-name TerraformPolicy \
  --policy-document file://terraform-policy.json
```

## Application Deployment

### Manual Deployment

1. **Build Docker Images** (locally or via CI/CD)
   ```bash
   docker build -t skep-api-gateway:latest ./services/api-gateway
   docker tag skep-api-gateway:latest ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com/skep-api-gateway:latest

   # Login to ECR
   aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com

   # Push image
   docker push ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com/skep-api-gateway:latest
   ```

2. **Update ECS Service**
   ```bash
   aws ecs update-service \
     --cluster skep-cluster-dev \
     --service skep-api-gateway-dev \
     --force-new-deployment \
     --region ap-northeast-2
   ```

3. **Verify Deployment**
   ```bash
   aws ecs describe-services \
     --cluster skep-cluster-dev \
     --services skep-api-gateway-dev \
     --region ap-northeast-2
   ```

### Automated Deployment via GitHub Actions

1. **Push to develop branch** (triggers `deploy-dev.yml`)
   ```bash
   git checkout develop
   git commit -m "Deploy to dev"
   git push origin develop
   ```

2. **Push to main branch** (triggers `deploy-prod.yml` with approval)
   ```bash
   git checkout main
   git commit -m "Deploy to prod"
   git push origin main
   # Manual approval required in GitHub Actions
   ```

### Rolling Updates

The default deployment configuration uses:
- `maximum_percent: 200` - Allows 2x the desired task count during deployment
- `minimum_healthy_percent: 100` - Ensures 100% uptime

This enables zero-downtime rolling updates.

## Monitoring and Operations

### CloudWatch Logs
```bash
# View API Gateway logs
aws logs tail /ecs/skep-dev --follow

# View specific service logs
aws logs tail /ecs/skep-dev/api-gateway --follow
```

### ECS Service Status
```bash
# Check service status
aws ecs describe-services \
  --cluster skep-cluster-dev \
  --services skep-api-gateway-dev

# Check running tasks
aws ecs list-tasks \
  --cluster skep-cluster-dev \
  --service-name skep-api-gateway-dev
```

### RDS Database Monitoring
```bash
# Get database endpoint
aws rds describe-db-clusters \
  --db-cluster-identifier skep-cluster-dev \
  --query 'DBClusters[0].Endpoint'

# Connect to database
psql -h <endpoint> -U postgres -d skep
```

### Redis Cache Monitoring
```bash
# Get Redis endpoint
aws elasticache describe-replication-groups \
  --replication-group-id skep-redis-dev
```

### CloudWatch Alarms
```bash
# List all alarms
aws cloudwatch describe-alarms \
  --region ap-northeast-2 \
  --query 'MetricAlarms[?contains(AlarmName, `skep`)]'
```

## Troubleshooting

### Terraform Issues

**State Lock**
```bash
# View locks
aws dynamodb scan --table-name terraform-locks-dev

# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

**Destroy Resources**
```bash
# Plan destruction
terraform plan -destroy

# Destroy (removes all resources!)
terraform destroy

# Destroy specific resource
terraform destroy -target=aws_ecs_service.api_gateway
```

### ECS Deployment Issues

**Service Fails to Start**
```bash
# Check service logs
aws logs tail /ecs/skep-dev --follow

# Check service events
aws ecs describe-services --cluster skep-cluster-dev --services skep-api-gateway-dev
```

**Task Fails to Register**
```bash
# Check task definition
aws ecs describe-task-definition --task-definition skep-api-gateway-dev

# Register new task definition
aws ecs register-task-definition --cli-input-json file://task-definition.json
```

### Database Connection Issues

**Check Security Groups**
```bash
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=skep-sg-rds-dev"
```

**Verify Parameter Store Values**
```bash
aws ssm get-parameter \
  --name /skep/dev/db/endpoint \
  --region ap-northeast-2

aws ssm get-parameter \
  --name /skep/dev/db/password \
  --with-decryption \
  --region ap-northeast-2
```

## Disaster Recovery

### Backup and Restore

**RDS Automated Backups**
- Retention period: 7 days
- Automatic backups are enabled
- Manual snapshots can be created:
```bash
aws rds create-db-cluster-snapshot \
  --db-cluster-identifier skep-cluster-prod \
  --db-cluster-snapshot-identifier skep-cluster-prod-backup-$(date +%Y%m%d)
```

**Redis Snapshots**
- Automatic snapshots: 7-day retention
- Restore from snapshot:
```bash
aws elasticache create-replication-group \
  --replication-group-description "Restored from snapshot" \
  --snapshot-name <snapshot-name>
```

## Maintenance

### Terraform Module Updates
```bash
terraform init -upgrade
terraform plan
terraform apply
```

### Security Updates
- Monitor AWS security bulletins
- Update Terraform provider regularly
- Review IAM policies quarterly
- Rotate credentials every 90 days

## Cost Optimization

### Resource Sizing
- Dev: t3.medium (RDS), t3.micro (ElastiCache)
- Prod: r6g.large (RDS), r6g.large (ElastiCache)
- Adjust based on actual usage

### Unused Resources
```bash
# Identify unattached resources
aws ec2 describe-addresses --filters "Name=association-id,Values="

# Remove unused load balancers
aws elbv2 describe-load-balancers
```

## Additional Resources

- [AWS Documentation](https://aws.amazon.com)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
