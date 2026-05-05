#!/bin/bash
# Phase 4: E2E Integration Test

BASE="http://localhost:8081/api"
PASS=0
FAIL=0

echo "=== PHASE 4: E2E INTEGRATION TESTS ==="
echo ""

# Get tokens
echo "[1/7] Getting authentication tokens..."
ADMIN_TOKEN=$(curl -s -X POST "$BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"ADMIN","password":"123456"}' | jq -r '.data.token // empty')

REG_TOKEN=$(curl -s -X POST "$BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"NV001","password":"123456"}' | jq -r '.data.token // empty')

STU_TOKEN=$(curl -s -X POST "$BASE/student/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"mssv":"2001215001","password":"123456"}' | jq -r '.data.token // empty')

if [ -n "$ADMIN_TOKEN" ] && [ -n "$REG_TOKEN" ] && [ -n "$STU_TOKEN" ]; then
  echo "✅ All tokens acquired"
  ((PASS++))
else
  echo "❌ Failed to get tokens"
  ((FAIL++))
  exit 1
fi

# Public endpoints
echo ""
echo "[2/7] Testing public endpoints..."
CAT_COUNT=$(curl -s "$BASE/public/service-categories" | jq '.data | length // 0')
if [ "$CAT_COUNT" -gt 0 ]; then
  echo "✅ Public categories endpoint"
  ((PASS++))
else
  echo "❌ Public categories endpoint"
  ((FAIL++))
fi

# Student endpoints
echo ""
echo "[3/7] Testing student protected endpoints..."
REQ_SUCCESS=$(curl -s "$BASE/student/requests" \
  -H "Authorization: Bearer $STU_TOKEN" | jq '.success')
if [ "$REQ_SUCCESS" = "true" ]; then
  echo "✅ Student requests list"
  ((PASS++))
else
  echo "❌ Student requests list"
  ((FAIL++))
fi

# Queue flow
echo ""
echo "[4/7] Testing queue flow..."
TICKET=$(curl -s -X POST "$BASE/student/queue/take" \
  -H "Authorization: Bearer $STU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"deskId":1}' | jq '.data.ticketNumber // empty')

CALLED=$(curl -s -X POST "$BASE/registrar/queue/1/call-next" \
  -H "Authorization: Bearer $REG_TOKEN" | jq '.data.ticketNumber // empty')

echo "Student ticket: $TICKET"
echo "Called ticket: $CALLED"

if [ "$TICKET" = "$CALLED" ]; then
  echo "✅ Queue matching"
  ((PASS++))
else
  echo "❌ Queue matching"
  ((FAIL++))
fi

# Security
echo ""
echo "[5/7] Testing security..."
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/student/profile")
if [ "$HTTP" = "401" ]; then
  echo "✅ Unauthenticated blocked (401)"
  ((PASS++))
else
  echo "❌ Unauthenticated (got $HTTP)"
  ((FAIL++))
fi

HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/registrar/dashboard" \
  -H "Authorization: Bearer $STU_TOKEN")
if [ "$HTTP" = "403" ]; then
  echo "✅ Role-based access control (403)"
  ((PASS++))
else
  echo "❌ Role-based access (got $HTTP)"
  ((FAIL++))
fi

# Rate limiting
echo ""
echo "[6/7] Testing rate limiting..."
RATE_PASS=0
for i in {1..7}; do
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"username":"x","password":"x"}')
  
  if [ $i -le 5 ] && [ "$HTTP" = "401" ]; then
    ((RATE_PASS++))
  elif [ $i -gt 5 ] && [ "$HTTP" = "429" ]; then
    ((RATE_PASS++))
  fi
done

if [ "$RATE_PASS" -eq 7 ]; then
  echo "✅ Rate limiting (5x401 then 429)"
  ((PASS++))
else
  echo "❌ Rate limiting ($RATE_PASS/7 correct)"
  ((FAIL++))
fi

# Summary
echo ""
echo "=== SUMMARY ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Total:  $((PASS + FAIL))"

if [ $FAIL -eq 0 ]; then
  echo ""
  echo "✅ All Phase 4 tests PASSED"
  exit 0
else
  echo ""
  echo "❌ Some tests failed"
  exit 1
fi
