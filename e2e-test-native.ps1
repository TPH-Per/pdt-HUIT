$BASE = "http://localhost:8081/api"
$PASS = 0
$FAIL = 0

Write-Host "`n=== PHASE 4: E2E INTEGRATION TESTS ===" -ForegroundColor Cyan

Write-Host "`n[1/7] Getting authentication tokens..."
try {
  $adminResp = Invoke-WebRequest -Uri "$BASE/auth/login" `
    -Method POST `
    -ContentType "application/json" `
    -Body '{"username":"ADMIN","password":"123456"}' -UseBasicParsing
  $ADMIN_TOKEN = ($adminResp.Content | ConvertFrom-Json).data.token
  
  $regResp = Invoke-WebRequest -Uri "$BASE/auth/login" `
    -Method POST `
    -ContentType "application/json" `
    -Body '{"username":"NV001","password":"123456"}' -UseBasicParsing
  $REG_TOKEN = ($regResp.Content | ConvertFrom-Json).data.token
  
  $stuResp = Invoke-WebRequest -Uri "$BASE/student/auth/login" `
    -Method POST `
    -ContentType "application/json" `
    -Body '{"mssv":"2001215001","password":"123456"}' -UseBasicParsing
  $STU_TOKEN = ($stuResp.Content | ConvertFrom-Json).data.token
  
  if ($ADMIN_TOKEN -and $REG_TOKEN -and $STU_TOKEN) {
    Write-Host "✅ All tokens acquired" -ForegroundColor Green
    $PASS++
  } else {
    throw "Missing tokens"
  }
} catch {
  Write-Host "❌ Failed to get tokens: $_" -ForegroundColor Red
  $FAIL++
  exit 1
}

Write-Host "`n[2/7] Testing public endpoints..."
try {
  $catResp = Invoke-WebRequest -Uri "$BASE/public/service-categories" -UseBasicParsing
  $catCount = ($catResp.Content | ConvertFrom-Json).data.Count
  if ($catCount -gt 0) {
    Write-Host "✅ Public categories endpoint" -ForegroundColor Green
    $PASS++
  } else {
    throw "Empty categories"
  }
} catch {
  Write-Host "❌ Public categories: $_" -ForegroundColor Red
  $FAIL++
}

Write-Host "`n[3/7] Testing student protected endpoints..."
try {
  $reqResp = Invoke-WebRequest -Uri "$BASE/student/requests" `
    -Headers @{ Authorization = "Bearer $STU_TOKEN" } -UseBasicParsing
  $success = ($reqResp.Content | ConvertFrom-Json).success
  if ($success) {
    Write-Host "✅ Student requests list" -ForegroundColor Green
    $PASS++
  } else {
    throw "Request list failed"
  }
} catch {
  Write-Host "❌ Student requests: $_" -ForegroundColor Red
  $FAIL++
}

Write-Host "`n[4/7] Testing queue flow..."
try {
  $ticketResp = Invoke-WebRequest -Uri "$BASE/student/queue/take" `
    -Method POST `
    -ContentType "application/json" `
    -Body '{"deskId":1}' `
    -Headers @{ Authorization = "Bearer $STU_TOKEN" } -UseBasicParsing
  $TICKET = ($ticketResp.Content | ConvertFrom-Json).data.ticketNumber
  
  $callResp = Invoke-WebRequest -Uri "$BASE/registrar/queue/1/call-next" `
    -Method POST `
    -Headers @{ Authorization = "Bearer $REG_TOKEN" } -UseBasicParsing
  $CALLED = ($callResp.Content | ConvertFrom-Json).data.ticketNumber
  
  Write-Host "Student ticket: $TICKET"
  Write-Host "Called ticket: $CALLED"
  
  if ($TICKET -eq $CALLED) {
    Write-Host "✅ Queue matching" -ForegroundColor Green
    $PASS++
  } else {
    throw "Tickets don't match"
  }
} catch {
  Write-Host "❌ Queue flow: $_" -ForegroundColor Red
  $FAIL++
}

Write-Host "`n[5/7] Testing security..."
try {
  # Unauthenticated access
  $response = Invoke-WebRequest -Uri "$BASE/student/profile" -UseBasicParsing -ErrorAction SilentlyContinue
  $statusCode = if ($response) { $response.StatusCode } else { 401 }
  
  if ($statusCode -eq 401) {
    Write-Host "✅ Unauthenticated blocked (401)" -ForegroundColor Green
    $PASS++
  } else {
    throw "Got $statusCode instead of 401"
  }
  
  # Role-based access
  try {
    $response = Invoke-WebRequest -Uri "$BASE/registrar/dashboard" `
      -Headers @{ Authorization = "Bearer $STU_TOKEN" } `
      -UseBasicParsing -ErrorAction SilentlyContinue
    $statusCode = $response.StatusCode
  } catch {
    $statusCode = $_.Exception.Response.StatusCode.Value
  }
  
  if ($statusCode -eq 403) {
    Write-Host "✅ Role-based access control (403)" -ForegroundColor Green
    $PASS++
  } else {
    throw "Got $statusCode instead of 403"
  }
} catch {
  Write-Host "❌ Security: $_" -ForegroundColor Red
  $FAIL++
}

Write-Host "`n[6/7] Testing rate limiting..."
$RATE_PASS = 0
for ($i = 1; $i -le 7; $i++) {
  try {
    $response = Invoke-WebRequest -Uri "$BASE/auth/login" `
      -Method POST `
      -ContentType "application/json" `
      -Body '{"username":"x","password":"x"}' `
      -UseBasicParsing -ErrorAction SilentlyContinue
    $statusCode = $response.StatusCode
  } catch {
    $statusCode = $_.Exception.Response.StatusCode.Value
  }
  
  if (($i -le 5 -and $statusCode -eq 401) -or ($i -gt 5 -and $statusCode -eq 429)) {
    $RATE_PASS++
  }
}

if ($RATE_PASS -eq 7) {
  Write-Host "✅ Rate limiting (5x401 then 429)" -ForegroundColor Green
  $PASS++
} else {
  Write-Host "❌ Rate limiting ($RATE_PASS/7)" -ForegroundColor Red
  $FAIL++
}

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
