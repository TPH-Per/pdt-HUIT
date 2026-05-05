$Base = "http://localhost:8081/api"
$Health = Invoke-RestMethod "http://localhost:8081/internal/actuator/health"
Write-Host "Health: $($Health.status)"

try {
    $metrics = Invoke-WebRequest "http://localhost:8081/actuator/metrics" -ErrorAction Stop
    Write-Host "FAIL: Actuator metrics returned 200"
} catch {
    Write-Host "Actuator secured: $($_.Exception.Response.StatusCode.value__)"
}

try {
    $profile = Invoke-WebRequest "$Base/student/profile" -ErrorAction Stop
    Write-Host "FAIL: Student profile returned 200 without auth"
} catch {
    Write-Host "Auth enforced: $($_.Exception.Response.StatusCode.value__)"
}

$AdminBody = @{ username="ADMIN"; password="123456" } | ConvertTo-Json
$AdminAuth = Invoke-RestMethod -Method Post -Uri "$Base/auth/login" -ContentType "application/json" -Body $AdminBody
$AdminToken = $AdminAuth.data.token

$RegBody = @{ username="NV001"; password="123456" } | ConvertTo-Json
$RegAuth = Invoke-RestMethod -Method Post -Uri "$Base/auth/login" -ContentType "application/json" -Body $RegBody
$RegToken = $RegAuth.data.token

$StuBody = @{ mssv="2001215001"; password="123456" } | ConvertTo-Json
$StuAuth = Invoke-RestMethod -Method Post -Uri "$Base/student/auth/login" -ContentType "application/json" -Body $StuBody
$StuToken = $StuAuth.data.token

Write-Host "Tokens: ADMIN=$($AdminToken.Substring(0,10))... REG=$($RegToken.Substring(0,10))... STU=$($StuToken.Substring(0,10))..."

$Categories = Invoke-RestMethod -Uri "$Base/public/service-categories"
Write-Host "Categories count: $($Categories.data.Count)"

$Profile = Invoke-RestMethod -Uri "$Base/student/profile" -Headers @{ Authorization = "Bearer $StuToken" }
Write-Host "Student ID: $($Profile.data.studentId)"

$QueueStats = Invoke-RestMethod -Uri "$Base/registrar/queue/1/stats" -Headers @{ Authorization = "Bearer $RegToken" }
Write-Host "Queue Stats waiting: $($QueueStats.data.waiting)"

$QueueCall = Invoke-RestMethod -Method Post -Uri "$Base/registrar/queue/1/call-next" -Headers @{ Authorization = "Bearer $RegToken" } -SkipHttpErrorCheck
if ($QueueCall.success) {
    Write-Host "Call next: Success - ticket $($QueueCall.data.ticketNumber)"
} else {
    Write-Host "Call next failed or returned 404/empty."
}
