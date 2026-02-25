# Database Restore Script for HANHCHINHCONGQ5CHOLON
# Use this script to restore database from backup

param(
    [Parameter(Mandatory=$true)]
    [string]$BackupFile,
    [string]$DbHost = "localhost",
    [string]$DbPort = "5432",
    [string]$DbName = "cholon_db",
    [string]$DbUser = "postgres",
    [switch]$Force
)

Write-Host "============================================"
Write-Host "  DATABASE RESTORE - $(Get-Date)"
Write-Host "============================================"

# Validate backup file
if (!(Test-Path $BackupFile)) {
    Write-Host "[ERROR] Backup file not found: $BackupFile" -ForegroundColor Red
    exit 1
}

$fileSize = (Get-Item $BackupFile).Length / 1MB
Write-Host "[INFO] Backup file: $BackupFile"
Write-Host "[INFO] File size: $([math]::Round($fileSize, 2)) MB"
Write-Host "[INFO] Target database: $DbName"

# Confirm restore
if (!$Force) {
    Write-Host ""
    Write-Host "⚠️  WARNING: This will REPLACE all data in database '$DbName'" -ForegroundColor Yellow
    Write-Host ""
    $confirm = Read-Host "Type 'YES' to confirm restore"
    
    if ($confirm -ne "YES") {
        Write-Host "[INFO] Restore cancelled by user"
        exit 0
    }
}

# Check if pg_restore exists
$pgRestore = Get-Command pg_restore -ErrorAction SilentlyContinue
if (!$pgRestore) {
    Write-Host "[ERROR] pg_restore not found. Please add PostgreSQL bin to PATH." -ForegroundColor Red
    exit 1
}

try {
    $startTime = Get-Date

    # Terminate existing connections
    Write-Host "[INFO] Terminating existing database connections..."
    & psql -U $DbUser -h $DbHost -p $DbPort -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DbName' AND pid <> pg_backend_pid();" 2>&1 | Out-Null

    # Restore database
    Write-Host "[INFO] Starting restore..."
    & pg_restore -U $DbUser -h $DbHost -p $DbPort -d $DbName -c -v $BackupFile 2>&1 | Out-Null

    $endTime = Get-Date
    $duration = $endTime - $startTime

    Write-Host ""
    Write-Host "[SUCCESS] Database restored successfully in $([math]::Round($duration.TotalMinutes, 2)) minutes" -ForegroundColor Green

} catch {
    Write-Host "[ERROR] Restore failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================"
Write-Host "  RESTORE COMPLETE"
Write-Host "============================================"
Write-Host "Database '$DbName' has been restored from:"
Write-Host "  $BackupFile"
Write-Host ""
Write-Host "Please verify the data and restart the application."
Write-Host "============================================"
