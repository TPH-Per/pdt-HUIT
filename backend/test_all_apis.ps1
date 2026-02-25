# ============================================================
# Test Script - All Student API Endpoints
# Phòng Đào tạo HUIT - Backend API Verification
# ============================================================

$BASE = "http://localhost:8081/api"
$MSSV = "2001230326"
$PASS = 0
$FAIL = 0
$TOTAL = 0
$ADMIN_TOKEN = ""

function Test-Api {
    param(
        [string]$Name,
        [string]$Method,
        [string]$Url,
        [string]$Body = $null,
        [int]$ExpectedStatus = 200,
        [string]$Token = ""
    )
    $script:TOTAL++
    Write-Host ""
    Write-Host "[$script:TOTAL] $Name" -ForegroundColor Cyan
    Write-Host "    $Method $Url" -ForegroundColor DarkGray

    try {
        $headers = @{}
        if ($Token) {
            $headers["Authorization"] = "Bearer $Token"
        }

        $params = @{
            Uri         = $Url
            Method      = $Method
            ContentType = "application/json"
            Headers     = $headers
            ErrorAction = "Stop"
        }
        if ($Body) {
            $params.Body = [System.Text.Encoding]::UTF8.GetBytes($Body)
        }

        $response = Invoke-WebRequest @params
        $status = $response.StatusCode

        if ($status -eq $ExpectedStatus) {
            $script:PASS++
            Write-Host "    PASS (HTTP $status)" -ForegroundColor Green
            $preview = $response.Content.Substring(0, [Math]::Min(100, $response.Content.Length))
            Write-Host "    $preview" -ForegroundColor DarkGreen
        }
        else {
            $script:FAIL++
            Write-Host "    FAIL - Expected $ExpectedStatus, got $status" -ForegroundColor Red
        }
        return $response.Content
    }
    catch {
        $ex = $_.Exception
        if ($ex.Response) {
            $actualStatus = [int]$ex.Response.StatusCode
            if ($actualStatus -eq $ExpectedStatus) {
                $script:PASS++
                Write-Host "    PASS (HTTP $actualStatus - expected)" -ForegroundColor Green
            }
            else {
                $script:FAIL++
                Write-Host "    FAIL - Expected $ExpectedStatus, got $actualStatus" -ForegroundColor Red
                Write-Host "    $($ex.Message)" -ForegroundColor Red
            }
        }
        else {
            $script:FAIL++
            Write-Host "    FAIL - $($ex.Message)" -ForegroundColor Red
        }
        return $null
    }
}

Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " Testing All Student API Endpoints" -ForegroundColor Yellow
Write-Host " Base URL: $BASE" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow

# ==================== Get Admin Token ====================
Write-Host ""
Write-Host "=== ADMIN LOGIN (get JWT token) ===" -ForegroundColor Magenta
$loginRes = Test-Api -Name "Admin Login" -Method "POST" -Url "$BASE/auth/login" -Body '{"username":"ADMIN","password":"123456"}'
if ($loginRes) {
    $loginJson = $loginRes | ConvertFrom-Json
    if ($loginJson.data.token) {
        $ADMIN_TOKEN = $loginJson.data.token
        Write-Host "    Token acquired!" -ForegroundColor Green
    }
}

# ==================== AUTH APIs ====================
Write-Host ""
Write-Host "=== AUTH APIs ===" -ForegroundColor Magenta

Test-Api -Name "POST /student/auth/register" -Method "POST" -Url "$BASE/student/auth/register" `
    -Body '{"mssv":"9999999999","fullName":"Test API User","password":"testpass123","major":"CNTT","phone":"0999888777","email":"test@huit.edu.vn"}'

Test-Api -Name "POST /student/auth/login" -Method "POST" -Url "$BASE/student/auth/login" `
    -Body '{"mssv":"9999999999","password":"testpass123"}'

Test-Api -Name "POST /student/auth/login (wrong pw)" -Method "POST" -Url "$BASE/student/auth/login" `
    -Body '{"mssv":"9999999999","password":"wrongpass"}' -ExpectedStatus 401

Test-Api -Name "POST /student/auth/change-password" -Method "POST" -Url "$BASE/student/auth/change-password" `
    -Body '{"mssv":"9999999999","oldPassword":"testpass123","newPassword":"newpass456"}'

Test-Api -Name "POST /student/auth/change-password (restore)" -Method "POST" -Url "$BASE/student/auth/change-password" `
    -Body '{"mssv":"9999999999","oldPassword":"newpass456","newPassword":"testpass123"}'

# ==================== PROFILE APIs ====================
Write-Host ""
Write-Host "=== PROFILE APIs ===" -ForegroundColor Magenta

Test-Api -Name "GET /student/profile" -Method "GET" -Url "$BASE/student/profile?mssv=9999999999"

Test-Api -Name "PUT /student/profile" -Method "PUT" -Url "$BASE/student/profile" `
    -Body '{"mssv":"9999999999","phone":"0912345678","email":"updated@huit.edu.vn"}'

Test-Api -Name "GET /student/profile (verify)" -Method "GET" -Url "$BASE/student/profile?mssv=9999999999"

# ==================== CATEGORY & SERVICE ====================
Write-Host ""
Write-Host "=== CATEGORY & SERVICE APIs ===" -ForegroundColor Magenta

Test-Api -Name "GET /student/categories" -Method "GET" -Url "$BASE/student/categories"
Test-Api -Name "GET /student/services" -Method "GET" -Url "$BASE/student/services"

# ==================== APPOINTMENT ====================
Write-Host ""
Write-Host "=== APPOINTMENT APIs ===" -ForegroundColor Magenta

$tomorrow = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
Test-Api -Name "GET /student/appointments/available-slots" -Method "GET" -Url "$BASE/student/appointments/available-slots?date=$tomorrow"
Test-Api -Name "GET /student/appointments?mssv=" -Method "GET" -Url "$BASE/student/appointments?mssv=$MSSV"

# ==================== REQUESTS ====================
Write-Host ""
Write-Host "=== REQUEST APIs ===" -ForegroundColor Magenta

Test-Api -Name "GET /student/requests?mssv=" -Method "GET" -Url "$BASE/student/requests?mssv=$MSSV"

# ==================== FEEDBACK ====================
Write-Host ""
Write-Host "=== FEEDBACK APIs ===" -ForegroundColor Magenta

Test-Api -Name "POST /student/feedback" -Method "POST" -Url "$BASE/student/feedback" `
    -Body '{"mssv":"9999999999","title":"Test feedback","content":"This is a test","type":1}'

Test-Api -Name "GET /student/feedback?mssv=" -Method "GET" -Url "$BASE/student/feedback?mssv=9999999999"

# ==================== REPORTS ====================
Write-Host ""
Write-Host "=== REPORT APIs ===" -ForegroundColor Magenta

Test-Api -Name "GET /student/reports?mssv=" -Method "GET" -Url "$BASE/student/reports?mssv=$MSSV"

# ==================== ADMIN STUDENT APIs (with JWT) ====================
Write-Host ""
Write-Host "=== ADMIN STUDENT APIs (JWT) ===" -ForegroundColor Magenta

Test-Api -Name "GET /admin/students" -Method "GET" -Url "$BASE/admin/students" -Token $ADMIN_TOKEN
Test-Api -Name "GET /admin/students/{mssv}" -Method "GET" -Url "$BASE/admin/students/9999999999" -Token $ADMIN_TOKEN

Test-Api -Name "POST /admin/students/{mssv}/reset-password" -Method "POST" `
    -Url "$BASE/admin/students/9999999999/reset-password" `
    -Body '{"newPassword":"resetpass123"}' -Token $ADMIN_TOKEN

# Verify login with reset password
Test-Api -Name "POST /student/auth/login (after reset)" -Method "POST" -Url "$BASE/student/auth/login" `
    -Body '{"mssv":"9999999999","password":"resetpass123"}'

# ==================== CLEANUP ====================
Write-Host ""
Write-Host "=== CLEANUP ===" -ForegroundColor Magenta

Test-Api -Name "DELETE /admin/students/{mssv}" -Method "DELETE" -Url "$BASE/admin/students/9999999999" -Token $ADMIN_TOKEN

# ==================== SUMMARY ====================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " TEST RESULTS" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host "  Total : $TOTAL" -ForegroundColor White
Write-Host "  Pass  : $PASS" -ForegroundColor Green
Write-Host "  Fail  : $FAIL" -ForegroundColor Red
Write-Host "============================================================" -ForegroundColor Yellow

if ($FAIL -eq 0) {
    Write-Host "  ALL TESTS PASSED!" -ForegroundColor Green
}
else {
    Write-Host "  SOME TESTS FAILED!" -ForegroundColor Red
}
