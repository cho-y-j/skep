#!/bin/bash

set -e

# ==========================================
# SKEP - Build All Docker Images
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
DOCKER_REGISTRY="${DOCKER_REGISTRY:-}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
SKIP_TESTS="${SKIP_TESTS:-false}"

# Services to build
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
    "ocr-service"
    "govapi-service"
    "frontend"
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

build_image() {
    local service=$1
    local service_path="${PROJECT_ROOT}/services/${service}"

    if [ ! -d "$service_path" ]; then
        log_warn "Service directory not found: $service_path"
        return 1
    fi

    local image_name="${DOCKER_REGISTRY}skep-${service}:${IMAGE_TAG}"

    log_info "Building Docker image for $service..."
    log_info "Image: $image_name"

    if docker build \
        --tag "$image_name" \
        --build-arg "SERVICE_NAME=$service" \
        --build-arg "BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --build-arg "VCS_REF=$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
        "$service_path"; then
        log_success "Successfully built $service"
        return 0
    else
        log_error "Failed to build $service"
        return 1
    fi
}

# ==========================================
# Main
# ==========================================

main() {
    log_info "Starting build process..."
    log_info "Image tag: $IMAGE_TAG"

    cd "$PROJECT_ROOT"

    if [ ! -f .env ]; then
        log_warn ".env file not found. Creating from .env.example..."
        cp .env.example .env
    fi

    # Load environment variables
    set +a
    source .env
    set -a

    local failed_services=()
    local successful_services=()

    for service in "${SERVICES[@]}"; do
        if build_image "$service"; then
            successful_services+=("$service")
        else
            failed_services+=("$service")
        fi
        echo ""
    done

    # Summary
    log_info "Build Summary:"
    log_success "Successful builds: ${#successful_services[@]}"
    for service in "${successful_services[@]}"; do
        echo "  ✓ $service"
    done

    if [ ${#failed_services[@]} -gt 0 ]; then
        log_error "Failed builds: ${#failed_services[@]}"
        for service in "${failed_services[@]}"; do
            echo "  ✗ $service"
        done
        exit 1
    else
        log_success "All services built successfully!"
        exit 0
    fi
}

# ==========================================
# Help
# ==========================================

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build all Docker images for SKEP microservices.

OPTIONS:
    -r, --registry REGISTRY    Docker registry URL (e.g., 123456789.dkr.ecr.ap-northeast-2.amazonaws.com/)
    -t, --tag TAG              Docker image tag (default: latest)
    -s, --skip-tests           Skip running tests before building
    -h, --help                 Show this help message

EXAMPLES:
    $0
    $0 --tag v1.0.0
    $0 --registry 123456789.dkr.ecr.ap-northeast-2.amazonaws.com/ --tag prod
    $0 --skip-tests

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--registry)
            DOCKER_REGISTRY="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -s|--skip-tests)
            SKIP_TESTS="true"
            shift
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

# Validate Docker is installed
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed or not in PATH"
    exit 1
fi

# Run main
main
