#!/bin/bash
BASE="http://localhost:8081/api"

echo "Checking health..."
curl.exe -s http://localhost:8081/internal/actuator/health

echo "Checking sealed actuator..."
HTTP=$(curl.exe -s -o /dev/null -w '%{http_code}' http://localhost:8081/actuator/metrics)
[ "$HTTP" = "404" ] && echo "✅ Actuator secured" || echo "❌ FAIL: $HTTP"

echo "Checking student route requires auth..."
HTTP=$(curl.exe -s -o /dev/null -w '%{http_code}' $BASE/student/profile)
[ "$HTTP" = "401" ] && echo "✅ Auth enforced" || echo "❌ FAIL: $HTTP"

echo "Getting tokens..."
ADMIN_TOKEN=$(curl.exe -s -X POST $BASE/auth/login -H "Content-Type: application/json" -d '{"username":"ADMIN","password":"123456"}' | jq -r '.data.token')
REG_TOKEN=$(curl.exe -s -X POST $BASE/auth/login -H "Content-Type: application/json" -d '{"username":"NV001","password":"123456"}' | jq -r '.data.token')
STU_TOKEN=$(curl.exe -s -X POST $BASE/student/auth/login -H "Content-Type: application/json" -d '{"mssv":"2001215001","password":"123456"}' | jq -r '.data.token')

echo "Tokens: ADMIN=${ADMIN_TOKEN:0:15} REG=${REG_TOKEN:0:15} STU=${STU_TOKEN:0:15}"

echo "Public endpoints..."
curl.exe -s $BASE/public/service-categories | jq '{count: (.data | length)}'

echo "Student endpoints..."
curl.exe -s $BASE/student/profile -H "Authorization: Bearer $STU_TOKEN" | jq '.data.studentId'

echo "Registrar endpoints..."
curl.exe -s $BASE/registrar/queue/1/stats -H "Authorization: Bearer $REG_TOKEN" | jq '.data'

echo "Done."
