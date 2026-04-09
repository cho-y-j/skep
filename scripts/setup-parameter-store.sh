#!/bin/bash

# SKEP AWS Parameter Store Setup Script
# Sets up all required parameters for dev and prod environments

set -e

ENVIRONMENT="${1:-dev}"
REGION="ap-northeast-2"

if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
    echo "Error: Environment must be 'dev' or 'prod'"
    exit 1
fi

echo "Setting up Parameter Store for environment: $ENVIRONMENT"

# Read sensitive values from user
read -sp "Enter DB Master Password: " DB_PASSWORD
echo
read -sp "Enter Redis Auth Token: " REDIS_AUTH_TOKEN
echo

# Database Parameters
echo "Setting up database parameters..."
aws ssm put-parameter \
    --name "/skep/$ENVIRONMENT/db/username" \
    --value "postgres" \
    --type "String" \
    --overwrite \
    --region "$REGION" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Service,Value=database"

aws ssm put-parameter \
    --name "/skep/$ENVIRONMENT/db/password" \
    --value "$DB_PASSWORD" \
    --type "SecureString" \
    --overwrite \
    --region "$REGION" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Service,Value=database"

aws ssm put-parameter \
    --name "/skep/$ENVIRONMENT/db/name" \
    --value "skep" \
    --type "String" \
    --overwrite \
    --region "$REGION" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Service,Value=database"

# Redis Parameters
echo "Setting up Redis parameters..."
aws ssm put-parameter \
    --name "/skep/$ENVIRONMENT/redis/auth_token" \
    --value "$REDIS_AUTH_TOKEN" \
    --type "SecureString" \
    --overwrite \
    --region "$REGION" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Service,Value=cache"

# Application Configuration Parameters
echo "Setting up application configuration parameters..."

aws ssm put-parameter \
    --name "/skep/$ENVIRONMENT/app/log_level" \
    --value "INFO" \
    --type "String" \
    --overwrite \
    --region "$REGION" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Service,Value=application"

aws ssm put-parameter \
    --name "/skep/$ENVIRONMENT/app/max_connections" \
    --value "100" \
    --type "String" \
    --overwrite \
    --region "$REGION" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Service,Value=application"

# Email Configuration (SES)
echo "Setting up email configuration..."

aws ssm put-parameter \
    --name "/skep/$ENVIRONMENT/email/from_address" \
    --value "noreply@skep.on1.kr" \
    --type "String" \
    --overwrite \
    --region "$REGION" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Service,Value=email"

aws ssm put-parameter \
    --name "/skep/$ENVIRONMENT/email/smtp_host" \
    --value "email-smtp.$REGION.amazonaws.com" \
    --type "String" \
    --overwrite \
    --region "$REGION" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Service,Value=email"

# Auth Configuration
echo "Setting up authentication configuration..."

# Generate JWT secret (32 random characters)
JWT_SECRET=$(openssl rand -base64 32)

aws ssm put-parameter \
    --name "/skep/$ENVIRONMENT/auth/jwt_secret" \
    --value "$JWT_SECRET" \
    --type "SecureString" \
    --overwrite \
    --region "$REGION" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Service,Value=auth"

aws ssm put-parameter \
    --name "/skep/$ENVIRONMENT/auth/jwt_expiration_hours" \
    --value "24" \
    --type "String" \
    --overwrite \
    --region "$REGION" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Service,Value=auth"

# Notification Settings
echo "Setting up notification settings..."

aws ssm put-parameter \
    --name "/skep/$ENVIRONMENT/notification/enabled" \
    --value "true" \
    --type "String" \
    --overwrite \
    --region "$REGION" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Service,Value=notification"

aws ssm put-parameter \
    --name "/skep/$ENVIRONMENT/notification/batch_size" \
    --value "100" \
    --type "String" \
    --overwrite \
    --region "$REGION" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Service,Value=notification"

# Cloud Storage Settings
echo "Setting up cloud storage settings..."

aws ssm put-parameter \
    --name "/skep/$ENVIRONMENT/storage/region" \
    --value "$REGION" \
    --type "String" \
    --overwrite \
    --region "$REGION" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Service,Value=storage"

# List all parameters
echo ""
echo "Parameter Store setup completed successfully!"
echo ""
echo "All parameters for $ENVIRONMENT environment:"
aws ssm describe-parameters \
    --parameter-filters "Key=Name,Values=/skep/$ENVIRONMENT" \
    --region "$REGION" \
    --query 'Parameters[*].[Name,Type,LastModifiedDate]' \
    --output table
