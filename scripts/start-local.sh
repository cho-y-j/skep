#!/bin/bash
# ============================================
# SKEP Local Development Starter
# 단계별 로컬 개발 환경 시작 스크립트
# ============================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

info()  { echo -e "${BLUE}[SKEP] $1${NC}"; }
ok()    { echo -e "${GREEN}[OK]   $1${NC}"; }
warn()  { echo -e "${YELLOW}[WARN] $1${NC}"; }
error() { echo -e "${RED}[ERR]  $1${NC}"; exit 1; }

STEP=${1:-all}

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    SKEP Platform - 로컬 시작 스크립트   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# .env 파일 확인
if [ ! -f .env ]; then
  warn ".env 파일이 없습니다. .env.example 복사 중..."
  cp .env.example .env
  warn ".env 파일을 편집하여 실제 값을 설정하세요: vi .env"
fi

start_infra() {
  info "단계 1: 인프라 시작 (PostgreSQL + Redis)"
  docker compose up -d postgres redis
  
  info "PostgreSQL 준비 대기 중..."
  until docker compose exec -T postgres pg_isready -U skep_user -d skep_db 2>/dev/null; do
    echo -n "."
    sleep 2
  done
  echo ""
  ok "PostgreSQL 준비 완료"
  
  info "Redis 준비 대기 중..."
  until docker compose exec -T redis redis-cli ping 2>/dev/null | grep -q PONG; do
    echo -n "."
    sleep 1
  done
  echo ""
  ok "Redis 준비 완료"
}

start_mocks() {
  info "단계 2: Mock 서비스 시작 (OCR + GovAPI)"
  docker compose up -d ocr-service govapi-service
  sleep 5
  
  if curl -sf http://localhost:8089/health > /dev/null 2>&1; then
    ok "OCR Mock 서비스 (port 8089) 준비 완료"
  else
    warn "OCR Mock 서비스 상태 확인 필요"
  fi
}

start_services() {
  info "단계 3: 백엔드 서비스 시작 (순차적)"
  
  # auth-service first (others depend on JWT validation)
  info "auth-service 시작 중..."
  docker compose up -d auth-service
  sleep 15
  
  # Remaining services in parallel
  info "나머지 서비스 시작 중..."
  docker compose up -d \
    document-service \
    equipment-service \
    dispatch-service \
    inspection-service \
    settlement-service \
    notification-service \
    location-service
  
  info "서비스 준비 대기 중 (최대 120초)..."
  timeout 120 bash -c 'until curl -sf http://localhost:8081/actuator/health 2>/dev/null | grep -q UP; do sleep 3; done' || warn "auth-service health check timeout"
  ok "백엔드 서비스 시작 완료"
}

start_gateway() {
  info "단계 4: API Gateway 시작"
  docker compose up -d api-gateway
  sleep 10
  timeout 60 bash -c 'until curl -sf http://localhost:8080/actuator/health 2>/dev/null | grep -q UP; do sleep 3; done' || warn "api-gateway health check timeout"
  ok "API Gateway (port 8080) 준비 완료"
}

start_frontend() {
  info "단계 5: Frontend 시작"
  docker compose up -d frontend
  sleep 10
  ok "Frontend (port 3000) 시작 완료"
  info "브라우저에서 접속: http://localhost:3000"
}

health_check() {
  echo ""
  info "═══ 전체 서비스 상태 ═══"
  docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker compose ps
  echo ""
  
  echo "Heath Check:"
  declare -A SVC_PORTS=(
    ["api-gateway"]=8080 ["auth-service"]=8081 ["document-service"]=8082
    ["equipment-service"]=8083 ["dispatch-service"]=8084 ["inspection-service"]=8085
    ["settlement-service"]=8086 ["notification-service"]=8087 ["location-service"]=8088
  )
  
  for svc in "${!SVC_PORTS[@]}"; do
    port="${SVC_PORTS[$svc]}"
    if curl -sf "http://localhost:$port/actuator/health" 2>/dev/null | grep -q '"UP"'; then
      echo -e "  ${GREEN}✓${NC} $svc :$port - UP"
    else
      echo -e "  ${RED}✗${NC} $svc :$port - DOWN or starting"
    fi
  done
}

case $STEP in
  infra)    start_infra ;;
  mocks)    start_mocks ;;
  services) start_services ;;
  gateway)  start_gateway ;;
  frontend) start_frontend ;;
  health)   health_check ;;
  all)
    start_infra
    start_mocks
    start_services
    start_gateway
    start_frontend
    health_check
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       SKEP 플랫폼 시작 완료!            ║${NC}"
    echo -e "${GREEN}║  Frontend:   http://localhost:3000       ║${NC}"
    echo -e "${GREEN}║  API:        http://localhost:8080       ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    ;;
  *)
    echo "Usage: $0 [all|infra|mocks|services|gateway|frontend|health]"
    exit 1
    ;;
esac
