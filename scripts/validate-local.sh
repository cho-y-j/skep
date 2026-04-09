#!/bin/bash
# ============================================
# SKEP Local Validation Script
# 로컬 환경 검증 스크립트
# ============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

check() {
  local desc="$1"
  local cmd="$2"
  echo -n "  ⬡ $desc... "
  if eval "$cmd" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}"
    ((PASS++))
  else
    echo -e "${RED}✗ FAIL${NC}"
    ((FAIL++))
  fi
}

info() { echo -e "${BLUE}► $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     SKEP Platform - 로컬 환경 검증      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# ─────────────────────────────
# 1. Prerequisites
# ─────────────────────────────
info "1. Prerequisites 체크"
check "Docker installed"        "docker --version"
check "Docker Compose available" "docker compose version || docker-compose --version"
check "Java 21 available"       "java -version 2>&1 | grep '21\\.'"
check "Git available"           "git --version"
check "curl available"          "curl --version"
echo ""

# ─────────────────────────────
# 2. Project Structure
# ─────────────────────────────
info "2. 프로젝트 구조 검증"
for svc in api-gateway auth-service document-service equipment-service dispatch-service inspection-service settlement-service notification-service location-service; do
  check "$svc/Dockerfile"     "[ -f services/$svc/Dockerfile ]"
  check "$svc/build.gradle"   "[ -f services/$svc/build.gradle ]"
  check "$svc/settings.gradle" "[ -f services/$svc/settings.gradle ]"
done
check "ocr-service"   "[ -f services/ocr-service/server.js ]"
check "govapi-service" "[ -f services/govapi-service/server.js ]"
check "Flutter pubspec" "[ -f frontend/skep_app/pubspec.yaml ]"
check "Flutter Dockerfile" "[ -f frontend/skep_app/Dockerfile ]"
echo ""

# ─────────────────────────────
# 3. Docker Compose Check
# ─────────────────────────────
info "3. Docker Compose 설정 검증"
check "docker-compose.yml syntax" "docker compose -f docker-compose.yml config --quiet"
check ".env.example exists" "[ -f .env.example ]"
echo ""

# ─────────────────────────────
# 4. Terraform Check (optional)
# ─────────────────────────────
if command -v terraform &>/dev/null; then
  info "4. Terraform 검증"
  check "terraform init (dev)" "cd infrastructure/terraform/environments/dev && terraform init -backend=false -input=false && cd -"
  check "terraform validate (dev)" "cd infrastructure/terraform/environments/dev && terraform validate && cd -"
else
  warn "Terraform not installed - skipping"
fi
echo ""

# ─────────────────────────────
# 5. Docker Service Check
# ─────────────────────────────
info "5. Docker 서비스 상태 확인"
if docker compose ps 2>/dev/null | grep -q "Up"; then
  check "postgres running" "docker compose ps postgres | grep -q 'Up\|running'"
  check "redis running"    "docker compose ps redis | grep -q 'Up\|running'"
  
  info "6. Health Check"
  for port_svc in "8081:auth-service" "8082:document-service" "8083:equipment-service" "8084:dispatch-service" "8085:inspection-service" "8086:settlement-service" "8087:notification-service" "8088:location-service"; do
    port="${port_svc%%:*}"
    svc="${port_svc##*:}"
    check "$svc health" "curl -sf http://localhost:$port/actuator/health | grep -q 'UP'"
  done
  
  info "7. API Gateway Check"
  check "api-gateway health" "curl -sf http://localhost:8080/actuator/health | grep -q 'UP'"
  check "auth endpoint" "curl -sf -o /dev/null -w '%{http_code}' http://localhost:8080/api/auth/login -X POST -H 'Content-Type: application/json' -d '{\"email\":\"test\",\"password\":\"test\"}' | grep -qE '400|401|200'"
else
  warn "Docker services not running. Start with: docker compose up -d"
fi
echo ""

# ─────────────────────────────
# Summary
# ─────────────────────────────
echo "──────────────────────────────"
echo -e "  결과: ${GREEN}$PASS passed${NC} / ${RED}$FAIL failed${NC}"
echo "──────────────────────────────"

if [ $FAIL -gt 0 ]; then
  echo -e "${YELLOW}일부 검증 실패. 위 오류를 확인하세요.${NC}"
  exit 1
else
  echo -e "${GREEN}모든 검증 통과!${NC}"
fi
