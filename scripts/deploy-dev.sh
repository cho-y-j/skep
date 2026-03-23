#!/bin/bash

set -e

# ==========================================
# SKEP - Deploy to Development Environment
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-ap-northeast-2}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
ECS_CLUSTER="${ECS_CLUSTER:-skep-dev-cluster}"
ECR_REGISTRY=""

# Services to deploy
SERVICES=(
    "api-gateway"
    "auth-service"
    "document-service"
    "equipment-service"
    "dispatch-service"
    "inspection-service"
    "settlement-service"
    "notification-service"
    "location-service"
)

# ==========================================
# Functions
# ==========================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

validate_prerequisites() {
    log_info "Validating prerequisites..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi

    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi

    if [ -z "$AWS_ACCOUNT_ID" ]; then
        log_error "AWS_ACCOUNT_ID is not set"
        exit 1
    fi

    ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    log_success "Prerequisites validated"
}

load_environment() {
    log_info "Loading environment variables..."

    cd "$PROJECT_ROOT"

    if [ ! -f .env ]; then
        log_error ".env file not found"
        exit 1
    fi

    set +a
    source .env
    set -a

    log_success "Environment loaded"
}

login_to_ecr() {
    log_info "Logging in to ECR..."

    aws ecr get-login-password --region "$AWS_REGION" | \
        docker login --username AWS --password-stdin "$ECR_REGISTRY"

    log_success "Logged in to ECR"
}

push_images() {
    log_info "Pushing Docker images to ECR..."

    local failed_services=()

    for service in "${SERVICES[@]}"; do
        local local_image="skep-${service}:${IMAGE_TAG}"
        local remote_image="${ECR_REGISTRY}/skep-${service}:${IMAGE_TAG}"
        local remote_image_latest="${ECR_REGISTRY}/skep-${service}:latest"

        log_info "Pushing $service..."

        if docker tag "$local_image" "$remote_image" 2>/dev/null; then
            if docker push "$remote_image"; then
                docker tag "$remote_image" "$remote_image_latest"
                docker push "$remote_image_latest"
                log_success "Pushed $service"
            else
                log_error "Failed to push $service"
                failed_services+=("$service")
            fi
        else
            log_warn "Local image not found: $local_image (skipping push)"
        fi
    done

    if [ ${#failed_services[@]} -gt 0 ]; then
        log_error "Failed to push images: ${failed_services[*]}"
        return 1
    fi

    log_success "All images pushed successfully"
    return 0
}

update_ecs_services() {
    log_info "Updating ECS services..."

    local failed_services=()

    for service in "${SERVICES[@]}"; do
        local ecs_service_name="skep-${service}-${ENVIRONMENT}"
        local task_family="skep-${service}"

        log_info "Updating ECS service: $ecs_service_name..."

        # Get current task definition
        local task_def=$(aws ecs describe-task-definition \
            --task-definition "$task_family" \
            --region "$AWS_REGION" \
            --query 'taskDefinition' \
            --output json)

        if [ -z "$task_def" ]; then
            log_warn "Task definition not found: $task_family (skipping)"
            continue
        fi

        # Update image in task definition
        local new_task_def=$(echo "$task_def" | \
            jq --arg IMAGE "${ECR_REGISTRY}/skep-${service}:${IMAGE_TAG}" \
            '.containerDefinitions[0].image = $IMAGE | .revision = null | .taskDefinitionArn = null | .status = null | del(.compatibilities)')

        # Register new task definition
        local new_task_def_arn=$(aws ecs register-task-definition \
            --region "$AWS_REGION" \
            --cli-input-json "$new_task_def" \
            --query 'taskDefinition.taskDefinitionArn' \
            --output text)

        if [ -z "$new_task_def_arn" ]; then
            log_error "Failed to register task definition for $service"
            failed_services+=("$service")
            continue
        fi

        # Update ECS service
        if aws ecs update-service \
            --cluster "$ECS_CLUSTER" \
            --service "$ecs_service_name" \
            --task-definition "$new_task_def_arn" \
            --region "$AWS_REGION" > /dev/null; then
            log_success "Updated ECS service: $ecs_service_name"
        else
            log_error "Failed to update ECS service: $ecs_service_name"
            failed_services+=("$service")
        fi
    done

    if [ ${#failed_services[@]} -gt 0 ]; then
        log_error "Failed to update services: ${failed_services[*]}"
        return 1
    fi

    log_success "All ECS services updated successfully"
    return 0
}

wait_for_deployment() {
    log_info "Waiting for services to be updated..."

    local max_attempts=30
    local attempt=1
    local all_stable=false

    while [ $attempt -le $max_attempts ]; do
        local all_running=true

        for service in "${SERVICES[@]}"; do
            local ecs_service_name="skep-${service}-${ENVIRONMENT}"

            local service_status=$(aws ecs describe-services \
                --cluster "$ECS_CLUSTER" \
                --services "$ecs_service_name" \
                --region "$AWS_REGION" \
                --query 'services[0].deployments[0].status' \
                --output text 2>/dev/null || echo "UNKNOWN")

            if [ "$service_status" != "PRIMARY" ]; then
                all_running=false
                log_info "  $ecs_service_name: $service_status (attempt $attempt/$max_attempts)"
            fi
        done

        if [ "$all_running" = true ]; then
            all_stable=true
            break
        fi

        sleep 10
        attempt=$((attempt + 1))
    done

    if [ "$all_stable" = true ]; then
        log_success "All services deployed successfully"
        return 0
    else
        log_warn "Deployment timeout - services may still be updating"
        return 1
    fi
}

# ==========================================
# Main
# ==========================================

main() {
    log_info "Starting deployment to $ENVIRONMENT environment..."
    log_info "Image tag: $IMAGE_TAG"
    log_info "AWS Region: $AWS_REGION"
    log_info "ECS Cluster: $ECS_CLUSTER"

    validate_prerequisites
    load_environment
    login_to_ecr
    push_images
    update_ecs_services
    wait_for_deployment

    log_success "Deployment completed successfully!"
}

# ==========================================
# Help
# ==========================================

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy SKEP services to development ECS environment.

OPTIONS:
    -a, --account-id ACCOUNT_ID    AWS Account ID
    -r, --region REGION            AWS Region (default: ap-northeast-2)
    -t, --tag TAG                  Docker image tag (default: latest)
    -c, --cluster CLUSTER          ECS cluster name (default: skep-dev-cluster)
    -e, --environment ENV          Environment name (default: dev)
    -h, --help                     Show this help message

EXAMPLES:
    $0 --account-id 123456789
    $0 --account-id 123456789 --tag v1.0.0
    $0 --account-id 123456789 --region ap-northeast-2 --tag prod

REQUIREMENTS:
    - Docker installed and running
    - AWS CLI installed and configured
    - AWS_ACCOUNT_ID environment variable or --account-id flag
    - Appropriate AWS IAM permissions for ECR and ECS

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--account-id)
            AWS_ACCOUNT_ID="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -c|--cluster)
            ECS_CLUSTER="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

main
