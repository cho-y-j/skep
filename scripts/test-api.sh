#!/bin/bash
# ============================================
# SKEP API Quick Test Script
# 로컬 API 엔드포인트 빠른 테스트
# ============================================

BASE_URL="${API_URL:-http://localhost:8080}"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

pass=0; fail=0

test_api() {
  local desc="$1"
  local method="$2"
  local path="$3"
  local data="$4"
  local expected="$5"
  
  if [ -n "$data" ]; then
    status=$(curl -sf -o /tmp/skep_resp.json -w "%{http_code}" \
      -X "$method" "$BASE_URL$path" \
      -H "Content-Type: application/json" \
      -H "${AUTH_HEADER:-}" \
      -d "$data" 2>/dev/null)
  else
    status=$(curl -sf -o /tmp/skep_resp.json -w "%{http_code}" \
      -X "$method" "$BASE_URL$path" \
      -H "${AUTH_HEADER:-}" 2>/dev/null)
  fi
  
  if echo "$status" | grep -qE "$expected"; then
    echo -e "${GREEN}✓${NC} [$status] $desc"
    ((pass++))
  else
    echo -e "${RED}✗${NC} [$status] $desc (expected: $expected)"
    cat /tmp/skep_resp.json 2>/dev/null | head -3
    ((fail++))
  fi
}

echo ""
echo "── SKEP API Test ─────────────────────────"
echo "  Target: $BASE_URL"
echo "──────────────────────────────────────────"

# Health checks
echo ""
echo "[1] Health Checks"
test_api "API Gateway health"     GET "/actuator/health" "" "200"
test_api "Auth service health"    GET "/api/auth/actuator/health" "" "200|404"

# Auth
echo ""
echo "[2] Authentication"
test_api "Login - invalid creds"  POST "/api/auth/login" \
  '{"email":"invalid@test.com","password":"wrong"}' "400|401"

test_api "Register - missing fields" POST "/api/auth/register" \
  '{"email":"test@test.com"}' "400"

# Get admin token
ADMIN_RESP=$(curl -sf -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@skep.com","password":"Admin1234!"}' 2>/dev/null)
TOKEN=$(echo $ADMIN_RESP | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
  AUTH_HEADER="Authorization: Bearer $TOKEN"
  echo -e "  ${GREEN}✓ 관리자 로그인 성공 (token obtained)${NC}"
  
  echo ""
  echo "[3] Protected Endpoints"
  test_api "Equipment list"   GET "/api/equipment"   "" "200"
  test_api "Dispatch plans"   GET "/api/dispatch/plans" "" "200"
  test_api "Document list"    GET "/api/documents"   "" "200"
fi

echo ""
echo "──────────────────────────────────────────"
echo -e "  결과: ${GREEN}$pass passed${NC} / ${RED}$fail failed${NC}"
echo "──────────────────────────────────────────"
