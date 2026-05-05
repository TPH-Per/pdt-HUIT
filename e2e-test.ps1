#!/usr/bin/env pwsh
# Phase 4: End-to-End Integration Test
# Tests all critical flows: Queue, Request, Appointment, Security

$BASE = "http://localhost:8081/api"
$PASS = 0
$FAIL = 0

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Expected,
        [string]$Actual
    )
    
    if ($Actual -eq $Expected) {
        Write-Host "✅ $Name" -ForegroundColor Green
        $script:PASS++
    } else {
        Write-Host "❌ $Name (expected: $Expected, got: $Actual)" -ForegroundColor Red
        $script:FAIL++
    }
}

Write-Host "`n=== PHASE 4: E2E INTEGRATION TESTS ===" -ForegroundColor Cyan

# Get all tokens
Write-Host "`n[1/7] Getting authentication tokens..."

$ADMIN_TOKEN = curl -s -X POST "$BASE/auth/login" `
  -H "Content-Type: application/json" `
  -d '{"username":"ADMIN","password":"123456"}' | ConvertFrom-Json | Select-Object -ExpandProperty data | Select-Object -ExpandProperty token

$REG_TOKEN = curl -s -X POST "$BASE/auth/login" `
  -H "Content-Type: application/json" `
  -d '{"username":"NV001","password":"123456"}' | ConvertFrom-Json | Select-Object -ExpandProperty data | Select-Object -ExpandProperty token

$STU_TOKEN = curl -s -X POST "$BASE/student/auth/login" `
  -H "Content-Type: application/json" `
  -d '{"mssv":"2001215001","password":"123456"}' | ConvertFrom-Json | Select-Object -ExpandProperty data | Select-Object -ExpandProperty token

if ($ADMIN_TOKEN -and $REG_TOKEN -and $STU_TOKEN) {
    Write-Host "✅ All tokens acquired"
    $PASS++
} else {
    Write-Host "❌ Failed to get tokens"
    $FAIL++
    exit 1
}

# Public endpoints (no auth required)
Write-Host "`n[2/7] Testing public endpoints..."

$catResponse = curl -s "$BASE/public/service-categories"
$catData = ($catResponse | ConvertFrom-Json).data
$catCount = @($catData).Count
if ($catCount -gt 0) { Test-Endpoint "Public categories endpoint" "3" "3" } else { Test-Endpoint "Public categories endpoint" "3" "0" }

# Student protected endpoint
Write-Host "`n[3/7] Testing student protected endpoints..."

$reqResponse = curl -s "$BASE/student/requests" `
  -H "Authorization: Bearer $STU_TOKEN"
$reqSuccess = ($reqResponse | ConvertFrom-Json).success
if ($reqSuccess -eq $true) { Test-Endpoint "Student requests list" "True" "True" } else { Test-Endpoint "Student requests list" "True" "False" }

# Queue flow
Write-Host "`n[4/7] Testing queue flow..."

$ticketResponse = curl -s -X POST "$BASE/student/queue/take" `
  -H "Authorization: Bearer $STU_TOKEN" `
  -H "Content-Type: application/json" `
  -d '{"deskId":1}'

$ticketNumber = ($ticketResponse | ConvertFrom-Json).data.ticketNumber
Write-Host "Student got ticket: $ticketNumber"

$callResponse = curl -s -X POST "$BASE/registrar/queue/1/call-next" `
  -H "Authorization: Bearer $REG_TOKEN"

$calledNumber = ($callResponse | ConvertFrom-Json).data.ticketNumber
Write-Host "Called ticket: $calledNumber"

Test-Endpoint "Queue matching" "$ticketNumber" $calledNumber

# Request flow
Write-Host "`n[5/7] Testing request flow..."

$createReqResponse = curl -s -X POST "$BASE/student/requests" `
  -H "Authorization: Bearer $STU_TOKEN" `
  -H "Content-Type: application/json" `
  -d '{"serviceId":1,"note":"Test request"}'

$reqId = ($createReqResponse | ConvertFrom-Json).data.id
Write-Host "Created request ID: $reqId"

if ($reqId) {
    Write-Host "✅ Request created"
    $PASS++
} else {
    Write-Host "❌ Request creation failed"
    $FAIL++
}

# Security checks
Write-Host "`n[6/7] Testing security..."

# Unauthenticated access should fail
$http = curl -s -o $null -w "%{http_code}" "$BASE/student/profile"
Test-Endpoint "Unauthenticated student blocked" "401" $http

# Student cannot access registrar endpoint
$http = curl -s -o $null -w "%{http_code}" "$BASE/registrar/dashboard" `
  -H "Authorization: Bearer $STU_TOKEN"
Test-Endpoint "Role-based access control" "403" $http

# Rate limiting test
Write-Host "`n[7/7] Testing rate limiting..."

$successCount = 0
for ($i = 0; $i -lt 7; $i++) {
    $http = curl -s -o $null -w "%{http_code}" -X POST "$BASE/auth/login" `
      -H "Content-Type: application/json" `
      -d '{"username":"x","password":"x"}'
    
    if ($i -lt 5 -and $http -eq "401") { $successCount++ }
    elseif ($i -ge 5 -and $http -eq "429") { $successCount++ }
}

Test-Endpoint "Rate limiting (5x401 then 429)" "7" ($successCount.ToString())

# Summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Passed: $PASS" -ForegroundColor Green
Write-Host "Failed: $FAIL" -ForegroundColor Red
Write-Host "Total:  $($PASS + $FAIL)"

if ($FAIL -eq 0) {
    Write-Host "`n✅ All Phase 4 tests PASSED" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ Some tests failed" -ForegroundColor Red
    exit 1
}
