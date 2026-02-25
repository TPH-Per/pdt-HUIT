# Test Queue Logic - PowerShell Script
# Mục đích: Kiểm tra luồng "Yêu cầu bổ sung" và xem application có xuất hiện trong Queue không

$baseUrl = "http://localhost:8081/api"
$token = "" # Sẽ lấy sau khi login

# ========== 1. LOGIN ==========
Write-Host "========== STEP 1: LOGIN ==========" -ForegroundColor Cyan
$loginBody = @{
    staffCode = "NV001"
    password = "123456"
} | ConvertTo-Json

try {
    $loginRes = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
    $token = $loginRes.data.token
    Write-Host "Login OK. Token: $($token.Substring(0, 30))..." -ForegroundColor Green
} catch {
    Write-Host "Login FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# ========== 2. LẤY DANH SÁCH HỒ SƠ ==========
Write-Host "`n========== STEP 2: GET HOSO LIST ==========" -ForegroundColor Cyan
try {
    $hosoRes = Invoke-RestMethod -Uri "$baseUrl/staff/hoso" -Method GET -Headers $headers
    Write-Host "Total HoSo: $($hosoRes.data.Count)" -ForegroundColor Green
    
    # Tìm hồ sơ có trạng thái RECEIVED (5) hoặc PROCESSING (4)
    $targetHoso = $hosoRes.data | Where-Object { $_.trangThai -eq 5 -or $_.trangThai -eq 4 } | Select-Object -First 1
    
    if (-not $targetHoso) {
        # Nếu không có, lấy bất kỳ hồ sơ nào không phải CANCELLED/COMPLETED
        $targetHoso = $hosoRes.data | Where-Object { $_.trangThai -notin @(0, 4) } | Select-Object -First 1
    }
    
    if (-not $targetHoso) {
        Write-Host "Không tìm thấy hồ sơ phù hợp để test!" -ForegroundColor Red
        exit
    }
    
    Write-Host "Selected HoSo: ID=$($targetHoso.id), Ma=$($targetHoso.maHoSo), TrangThai=$($targetHoso.trangThai) ($($targetHoso.trangThaiText))" -ForegroundColor Yellow
} catch {
    Write-Host "Get HoSo FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# ========== 3. CẬP NHẬT TRẠNG THÁI SANG "BỔ SUNG" (6) ==========
Write-Host "`n========== STEP 3: UPDATE STATUS TO SUPPLEMENT (6) ==========" -ForegroundColor Cyan

$today = Get-Date -Format "yyyy-MM-dd"
$nextHour = (Get-Date).AddHours(1).ToString("HH:mm")

$updateBody = @{
    trangThaiMoi = 6  # PHASE_SUPPLEMENT
    noiDung = "Test bo sung - Script test"
    ngayHen = $today
    gioHen = $nextHour
} | ConvertTo-Json

Write-Host "Request Body: $updateBody" -ForegroundColor Gray

try {
    $updateRes = Invoke-RestMethod -Uri "$baseUrl/staff/hoso/$($targetHoso.id)/status" -Method PUT -Headers $headers -Body $updateBody
    Write-Host "Update Status OK: $($updateRes.message)" -ForegroundColor Green
    Write-Host "New Status: $($updateRes.data.trangThai) ($($updateRes.data.trangThaiText))" -ForegroundColor Green
} catch {
    Write-Host "Update Status FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    exit
}

# ========== 4. KIỂM TRA QUEUE DASHBOARD ==========
Write-Host "`n========== STEP 4: CHECK QUEUE DASHBOARD ==========" -ForegroundColor Cyan
try {
    $queueRes = Invoke-RestMethod -Uri "$baseUrl/staff/queue/dashboard" -Method GET -Headers $headers
    Write-Host "Queue Dashboard OK" -ForegroundColor Green
    Write-Host "Total Waiting: $($queueRes.data.totalWaiting)" -ForegroundColor Yellow
    
    # Kiểm tra xem hồ sơ vừa update có trong queue không
    $foundInQueue = $queueRes.data.waitingList | Where-Object { $_.id -eq $targetHoso.id }
    
    if ($foundInQueue) {
        Write-Host ">>> HoSo ID=$($targetHoso.id) FOUND in Queue! <<<" -ForegroundColor Green
        Write-Host "    Phase: $($foundInQueue.currentPhase), ExpectedTime: $($foundInQueue.expectedTime)" -ForegroundColor Green
    } else {
        Write-Host ">>> HoSo ID=$($targetHoso.id) NOT FOUND in Queue! <<<" -ForegroundColor Red
        Write-Host ""
        Write-Host "=== NGUYÊN NHÂN ===" -ForegroundColor Magenta
        Write-Host "Queue Dashboard chỉ query các application có:" -ForegroundColor White
        Write-Host "  - currentPhase = 3 (QUEUE) qua findActiveQueueHistories" -ForegroundColor White
        Write-Host "  - currentPhase = 2 (PENDING) qua findApplicationsByAppointmentDateAndPhase" -ForegroundColor White
        Write-Host ""
        Write-Host "Nhưng 'Yêu cầu bổ sung' set currentPhase = 6 (SUPPLEMENT)" -ForegroundColor White
        Write-Host "=> Application với phase=6 KHÔNG BAO GIỜ xuất hiện trong Queue!" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Queue Dashboard FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

# ========== 5. KIỂM TRA HISTORY ==========
Write-Host "`n========== STEP 5: CHECK APPLICATION HISTORY ==========" -ForegroundColor Cyan
try {
    $detailRes = Invoke-RestMethod -Uri "$baseUrl/staff/hoso/$($targetHoso.id)" -Method GET -Headers $headers
    Write-Host "Application Detail:" -ForegroundColor Green
    Write-Host "  ID: $($detailRes.data.id)" -ForegroundColor White
    Write-Host "  Ma: $($detailRes.data.maHoSo)" -ForegroundColor White
    Write-Host "  TrangThai: $($detailRes.data.trangThai) ($($detailRes.data.trangThaiText))" -ForegroundColor White
    
    Write-Host "`nLịch sử xử lý (mới nhất trước):" -ForegroundColor Yellow
    $detailRes.data.lichSuXuLy | Select-Object -First 5 | ForEach-Object {
        Write-Host "  [$($_.thoiGian)] $($_.hanhDong): $($_.trangThaiCu) -> $($_.trangThaiMoi)" -ForegroundColor Gray
    }
} catch {
    Write-Host "Get Detail FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n========== KẾT LUẬN ==========" -ForegroundColor Magenta
Write-Host "Nếu test ở trên cho kết quả 'NOT FOUND in Queue'," -ForegroundColor White
Write-Host "cần sửa logic getDashboard() trong StaffQueueController để:" -ForegroundColor White
Write-Host "  1. Thêm query cho PHASE_SUPPLEMENT (6)" -ForegroundColor Cyan
Write-Host "  2. HOẶC khi 'Yêu cầu bổ sung', set currentPhase = PHASE_QUEUE (3) thay vì SUPPLEMENT (6)" -ForegroundColor Cyan
