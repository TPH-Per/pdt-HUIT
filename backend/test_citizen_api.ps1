# Test Citizen API - PowerShell Script
# Mục đích: Kiểm tra các API dành cho công dân (Zalo Mini App)

$baseUrl = "http://localhost:8081/api/citizen"
$testCccd = "012345678912"
$testName = "Nguyen Van Test"
$testPhone = "0901234567"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  TEST API CITIZEN (Zalo Mini App Client)  " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ========== 1. LẤY DANH SÁCH CHUYÊN MÔN (LĨNH VỰC) ==========
Write-Host "========== 1. GET SPECIALTIES ==========" -ForegroundColor Yellow
try {
    $res = Invoke-RestMethod -Uri "$baseUrl/specialties" -Method GET -ContentType "application/json"
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Total Specialties: $($res.data.Count)" -ForegroundColor White
    $res.data | ForEach-Object {
        Write-Host "  - [$($_.id)] $($_.name)" -ForegroundColor Gray
    }
    $firstSpecialtyId = if ($res.data.Count -gt 0) { $res.data[0].id } else { $null }
} catch {
    Write-Host "Status: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# ========== 2. LẤY DANH SÁCH THỦ TỤC ==========
Write-Host "`n========== 2. GET PROCEDURES ==========" -ForegroundColor Yellow
try {
    $url = "$baseUrl/procedures"
    if ($firstSpecialtyId) {
        $url = "$baseUrl/procedures?specialtyId=$firstSpecialtyId"
    }
    $res = Invoke-RestMethod -Uri $url -Method GET -ContentType "application/json"
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Total Procedures: $($res.data.Count)" -ForegroundColor White
    $res.data | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - [$($_.id)] $($_.name) (Est: $($_.estimatedDays) days)" -ForegroundColor Gray
    }
    $testProcedureId = if ($res.data.Count -gt 0) { $res.data[0].id } else { 1 }
} catch {
    Write-Host "Status: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testProcedureId = 1
}

# ========== 3. LẤY SLOT KHẢ DỤNG ==========
Write-Host "`n========== 3. GET AVAILABLE SLOTS ==========" -ForegroundColor Yellow
$tomorrow = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
try {
    $res = Invoke-RestMethod -Uri "$baseUrl/appointments/available-slots?date=$tomorrow&procedureId=$testProcedureId" -Method GET -ContentType "application/json"
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Date: $($res.data.date)" -ForegroundColor White
    Write-Host "Total Slots: $($res.data.slots.Count)" -ForegroundColor White
    $availableSlots = $res.data.slots | Where-Object { $_.available -gt 0 }
    Write-Host "Available Slots: $($availableSlots.Count)" -ForegroundColor White
    $availableSlots | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - $($_.time) (Available: $($_.available)/$($_.maxCapacity))" -ForegroundColor Gray
    }
    $testSlotTime = if ($availableSlots.Count -gt 0) { $availableSlots[0].time } else { "09:00" }
} catch {
    Write-Host "Status: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testSlotTime = "09:00"
}

# ========== 4. ĐẶT LỊCH HẸN ==========
Write-Host "`n========== 4. CREATE APPOINTMENT ==========" -ForegroundColor Yellow
$appointmentBody = @{
    procedureId = $testProcedureId
    appointmentDate = $tomorrow
    appointmentTime = $testSlotTime
    citizenName = $testName
    citizenId = $testCccd
    phoneNumber = $testPhone
    notes = "Test tu Zalo Mini App"
} | ConvertTo-Json

Write-Host "Request Body:" -ForegroundColor Gray
Write-Host $appointmentBody -ForegroundColor DarkGray

try {
    $res = Invoke-RestMethod -Uri "$baseUrl/appointments" -Method POST -Body $appointmentBody -ContentType "application/json"
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Appointment Code: $($res.data.code)" -ForegroundColor White
    Write-Host "Queue Display: $($res.data.queueDisplay)" -ForegroundColor White
    Write-Host "Date: $($res.data.appointmentDate)" -ForegroundColor White
    Write-Host "Time: $($res.data.appointmentTime)" -ForegroundColor White
    $testAppointmentId = $res.data.id
    $testAppointmentCode = $res.data.code
} catch {
    Write-Host "Status: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
    $testAppointmentId = $null
}

# ========== 5. LẤY DANH SÁCH LỊCH HẸN ==========
Write-Host "`n========== 5. GET MY APPOINTMENTS ==========" -ForegroundColor Yellow
try {
    $res = Invoke-RestMethod -Uri "$baseUrl/appointments?cccd=$testCccd" -Method GET -ContentType "application/json"
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Total Appointments: $($res.data.Count)" -ForegroundColor White
    $res.data | Select-Object -First 5 | ForEach-Object {
        Write-Host "  - [$($_.id)] $($_.code) | $($_.procedureName) | $($_.status)" -ForegroundColor Gray
    }
} catch {
    Write-Host "Status: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# ========== 6. LẤY CHI TIẾT HỒ SƠ ==========
if ($testAppointmentId) {
    Write-Host "`n========== 6. GET APPLICATION DETAIL ==========" -ForegroundColor Yellow
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/applications/$testAppointmentId`?cccd=$testCccd" -Method GET -ContentType "application/json"
        Write-Host "Status: SUCCESS" -ForegroundColor Green
        Write-Host "Code: $($res.data.code)" -ForegroundColor White
        Write-Host "Procedure: $($res.data.procedureName)" -ForegroundColor White
        Write-Host "Status: $($res.data.status)" -ForegroundColor White
        Write-Host "Citizen: $($res.data.citizenName) ($($res.data.citizenId))" -ForegroundColor White
    } catch {
        Write-Host "Status: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ========== 7. LẤY LỊCH SỬ XỬ LÝ ==========
if ($testAppointmentId) {
    Write-Host "`n========== 7. GET APPLICATION HISTORY ==========" -ForegroundColor Yellow
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/applications/$testAppointmentId/history?cccd=$testCccd" -Method GET -ContentType "application/json"
        Write-Host "Status: SUCCESS" -ForegroundColor Green
        Write-Host "History Items: $($res.data.Count)" -ForegroundColor White
        $res.data | ForEach-Object {
            Write-Host "  - [$($_.createdAt)] $($_.action): $($_.statusFrom) -> $($_.statusTo)" -ForegroundColor Gray
        }
    } catch {
        Write-Host "Status: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ========== 8. TRA CỨU HÀNG CHỜ ==========
if ($testAppointmentCode) {
    Write-Host "`n========== 8. CHECK QUEUE STATUS ==========" -ForegroundColor Yellow
    try {
        $res = Invoke-RestMethod -Uri "$baseUrl/queue/$testAppointmentCode" -Method GET -ContentType "application/json"
        Write-Host "Status: SUCCESS" -ForegroundColor Green
        Write-Host "Ticket: $($res.data.ticketDisplay)" -ForegroundColor White
        Write-Host "Current Serving: $($res.data.currentServing)" -ForegroundColor White
        Write-Host "Waiting Count: $($res.data.waitingCount)" -ForegroundColor White
        Write-Host "Est. Wait: $($res.data.estimatedWaitMinutes) mins" -ForegroundColor White
        Write-Host "Queue Status: $($res.data.status)" -ForegroundColor White
    } catch {
        Write-Host "Status: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ========== 9. GỬI GÓP Ý ==========
Write-Host "`n========== 9. CREATE FEEDBACK ==========" -ForegroundColor Yellow
$feedbackBody = @{
    type = 0  # Gop y
    title = "Test gop y tu Mini App"
    content = "Day la noi dung gop y tu Zalo Mini App. Rat hay!"
    citizenId = $testCccd
    citizenName = $testName
    phone = $testPhone
} | ConvertTo-Json

try {
    $res = Invoke-RestMethod -Uri "$baseUrl/reports" -Method POST -Body $feedbackBody -ContentType "application/json"
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Feedback ID: $($res.data.id)" -ForegroundColor White
    Write-Host "Title: $($res.data.title)" -ForegroundColor White
    Write-Host "Status: $($res.data.status)" -ForegroundColor White
} catch {
    Write-Host "Status: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
}

# ========== 10. LẤY DANH SÁCH GÓP Ý ==========
Write-Host "`n========== 10. GET MY FEEDBACKS ==========" -ForegroundColor Yellow
try {
    $res = Invoke-RestMethod -Uri "$baseUrl/reports?cccd=$testCccd" -Method GET -ContentType "application/json"
    Write-Host "Status: SUCCESS" -ForegroundColor Green
    Write-Host "Total Feedbacks: $($res.data.Count)" -ForegroundColor White
    $res.data | ForEach-Object {
        Write-Host "  - [$($_.id)] $($_.title) | Status: $($_.status)" -ForegroundColor Gray
    }
} catch {
    Write-Host "Status: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# ========== 11. HỦY LỊCH HẸN (Optional) ==========
if ($testAppointmentId) {
    Write-Host "`n========== 11. CANCEL APPOINTMENT (Test) ==========" -ForegroundColor Yellow
    Write-Host "Skipping cancel to keep test data. Uncomment to test." -ForegroundColor DarkGray
    # try {
    #     $res = Invoke-RestMethod -Uri "$baseUrl/appointments/$testAppointmentId/cancel?cccd=$testCccd" -Method POST -ContentType "application/json"
    #     Write-Host "Status: SUCCESS" -ForegroundColor Green
    #     Write-Host "Message: $($res.message)" -ForegroundColor White
    # } catch {
    #     Write-Host "Status: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    # }
}

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "         TEST COMPLETED                     " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
