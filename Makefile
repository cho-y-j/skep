.PHONY: help up down restart logs build push deploy-dev deploy-prod clean health migrate

# Variables
SHELL := /bin/bash
PROJECT_NAME := skep
COMPOSE_FILE := docker-compose.yml
COMPOSE_PROD_FILE := docker-compose.prod.yml
ENV_FILE := .env

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

help:
	@echo "$(BLUE)SKEP Platform - Development Commands$(NC)"
	@echo ""
	@echo "$(GREEN)Compose Commands:$(NC)"
	@echo "  make up              - Start all services"
	@echo "  make down            - Stop all services"
	@echo "  make restart         - Restart all services"
	@echo "  make logs            - View service logs"
	@echo "  make health          - Check service health"
	@echo ""
	@echo "$(GREEN)Build & Deploy:$(NC)"
	@echo "  make build           - Build all Docker images"
	@echo "  make push            - Push images to registry"
	@echo "  make deploy-dev      - Deploy to dev environment"
	@echo "  make deploy-prod     - Deploy to production"
	@echo ""
	@echo "$(GREEN)Database:$(NC)"
	@echo "  make migrate         - Run database migrations"
	@echo "  make db-shell        - Open PostgreSQL shell"
	@echo "  make redis-shell     - Open Redis CLI"
	@echo ""
	@echo "$(GREEN)Cleanup:$(NC)"
	@echo "  make clean           - Remove all containers and volumes"
	@echo "  make clean-images    - Remove all images"
	@echo ""

# Compose Commands
up:
	@echo "$(BLUE)[INFO]$(NC) Starting all services..."
	@docker-compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)[SUCCESS]$(NC) Services started"
	@sleep 5
	@make health

down:
	@echo "$(BLUE)[INFO]$(NC) Stopping all services..."
	@docker-compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)[SUCCESS]$(NC) Services stopped"

restart:
	@echo "$(BLUE)[INFO]$(NC) Restarting all services..."
	@docker-compose -f $(COMPOSE_FILE) restart
	@echo "$(GREEN)[SUCCESS]$(NC) Services restarted"

logs:
	@docker-compose -f $(COMPOSE_FILE) logs -f

logs-gateway:
	@docker-compose -f $(COMPOSE_FILE) logs -f api-gateway

logs-auth:
	@docker-compose -f $(COMPOSE_FILE) logs -f auth-service

logs-db:
	@docker-compose -f $(COMPOSE_FILE) logs -f postgres

# Health Checks
health:
	@echo "$(BLUE)[INFO]$(NC) Checking service health..."
	@echo ""
	@echo "API Gateway:"
	@curl -s http://localhost:8080/actuator/health | jq '.' || echo "  Status: UNAVAILABLE"
	@echo ""
	@echo "Auth Service:"
	@curl -s http://localhost:8081/actuator/health | jq '.' || echo "  Status: UNAVAILABLE"
	@echo ""
	@echo "OCR Service:"
	@curl -s http://localhost:8089/actuator/health | jq '.' || echo "  Status: UNAVAILABLE"
	@echo ""
	@echo "Government API Service:"
	@curl -s http://localhost:8090/actuator/health | jq '.' || echo "  Status: UNAVAILABLE"
	@echo ""

# Build Commands
build:
	@echo "$(BLUE)[INFO]$(NC) Building Docker images..."
	@chmod +x scripts/build-all.sh
	@./scripts/build-all.sh

build-service:
	@echo "$(BLUE)[INFO]$(NC) Building service: $(SERVICE)"
	@docker-compose -f $(COMPOSE_FILE) build $(SERVICE)

# Push to Registry
push:
	@echo "$(RED)[WARNING]$(NC) This requires AWS credentials"
	@read -p "Enter Docker registry (default: latest): " REGISTRY; \
	docker-compose push $$REGISTRY

# Deploy Commands
deploy-dev:
	@echo "$(BLUE)[INFO]$(NC) Deploying to dev environment..."
	@chmod +x scripts/deploy-dev.sh
	@./scripts/deploy-dev.sh

deploy-prod:
	@echo "$(RED)[WARNING]$(NC) PRODUCTION DEPLOYMENT - This requires explicit approval"
	@chmod +x scripts/deploy-prod.sh
	@./scripts/deploy-prod.sh

# Database Commands
migrate:
	@echo "$(BLUE)[INFO]$(NC) Running database migrations..."
	@docker-compose -f $(COMPOSE_FILE) exec -T postgres psql -U skep_user -d skep_db -f /docker-entrypoint-initdb.d/init.sql

db-shell:
	@echo "$(BLUE)[INFO]$(NC) Opening PostgreSQL shell..."
	@docker-compose -f $(COMPOSE_FILE) exec postgres psql -U skep_user -d skep_db

redis-shell:
	@echo "$(BLUE)[INFO]$(NC) Opening Redis CLI..."
	@docker-compose -f $(COMPOSE_FILE) exec redis redis-cli

# Cleanup Commands
clean:
	@echo "$(YELLOW)[WARN]$(NC) Removing all containers and volumes..."
	@read -p "Are you sure? This will delete all data (yes/no): " CONFIRM; \
	if [ "$$CONFIRM" = "yes" ]; then \
		docker-compose -f $(COMPOSE_FILE) down -v; \
		echo "$(GREEN)[SUCCESS]$(NC) Cleanup completed"; \
	else \
		echo "$(BLUE)[INFO]$(NC) Cleanup cancelled"; \
	fi

clean-images:
	@echo "$(YELLOW)[WARN]$(NC) Removing all images..."
	@docker-compose -f $(COMPOSE_FILE) down --rmi all
	@echo "$(GREEN)[SUCCESS]$(NC) Images removed"

# Validation Commands
validate-env:
	@echo "$(BLUE)[INFO]$(NC) Validating .env file..."
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(RED)[ERROR]$(NC) .env file not found"; \
		cp .env.example .env; \
		echo "$(GREEN)[SUCCESS]$(NC) Created .env from .env.example"; \
	else \
		echo "$(GREEN)[SUCCESS]$(NC) .env file found"; \
	fi

validate-docker:
	@echo "$(BLUE)[INFO]$(NC) Checking Docker installation..."
	@docker --version
	@docker-compose --version

test-connection:
	@echo "$(BLUE)[INFO]$(NC) Testing service connections..."
	@echo ""
	@echo "Testing API Gateway..."
	@docker-compose -f $(COMPOSE_FILE) exec -T api-gateway curl -s http://localhost:8080/actuator/health > /dev/null && echo "$(GREEN)✓$(NC) Connected" || echo "$(RED)✗$(NC) Failed"
	@echo ""
	@echo "Testing PostgreSQL..."
	@docker-compose -f $(COMPOSE_FILE) exec -T postgres psql -U skep_user -d skep_db -c "SELECT 1" > /dev/null && echo "$(GREEN)✓$(NC) Connected" || echo "$(RED)✗$(NC) Failed"
	@echo ""
	@echo "Testing Redis..."
	@docker-compose -f $(COMPOSE_FILE) exec -T redis redis-cli ping > /dev/null && echo "$(GREEN)✓$(NC) Connected" || echo "$(RED)✗$(NC) Failed"
	@echo ""

# Development Commands
dev-setup:
	@echo "$(BLUE)[INFO]$(NC) Setting up development environment..."
	@make validate-env
	@make validate-docker
	@make up
	@make health

ps:
	@docker-compose -f $(COMPOSE_FILE) ps

stats:
	@docker stats

version:
	@echo "$(BLUE)SKEP Platform v1.0.0$(NC)"
	@echo ""
	@echo "Services:"
	@echo "  API Gateway: v1.0.0"
	@echo "  Auth Service: v1.0.0"
	@echo "  Document Service: v1.0.0"
	@echo "  Equipment Service: v1.0.0"
	@echo "  Dispatch Service: v1.0.0"
	@echo "  Inspection Service: v1.0.0"
	@echo "  Settlement Service: v1.0.0"
	@echo "  Notification Service: v1.0.0"
	@echo "  Location Service: v1.0.0"
	@echo ""
	@echo "Infrastructure:"
	@echo "  PostgreSQL: 16"
	@echo "  Redis: 7"
	@echo "  Java: 21"
	@echo "  Spring Boot: 3.2"
	@echo "  Node.js: 18"
	@echo ""

.DEFAULT_GOAL := help

# Quick start
start:
	@./scripts/start-local.sh all

# Validate local setup
validate:
	@./scripts/validate-local.sh

# Quick API test
test-api:
	@./scripts/test-api.sh

# Show service URLs
urls:
	@echo "$(BLUE)═══ SKEP Service URLs ═══$(NC)"
	@echo "  Frontend:     http://localhost:3000"
	@echo "  API Gateway:  http://localhost:8080"
	@echo "  Auth:         http://localhost:8081"
	@echo "  Document:     http://localhost:8082"
	@echo "  Equipment:    http://localhost:8083"
	@echo "  Dispatch:     http://localhost:8084"
	@echo "  Inspection:   http://localhost:8085"
	@echo "  Settlement:   http://localhost:8086"
	@echo "  Notification: http://localhost:8087"
	@echo "  Location:     http://localhost:8088"
