$body = @{
    procedureId = 4
    appointmentDate = "2026-02-03"
    appointmentTime = "10:00"
    citizenName = "Test User"
    citizenId = "012345678912"
    phoneNumber = "0901234567"
} | ConvertTo-Json -Depth 10

Write-Host "Request Body:"
Write-Host $body

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8081/api/citizen/appointments" -Method POST -Body $body -ContentType "application/json"
    Write-Host "SUCCESS!"
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody"
    }
}
