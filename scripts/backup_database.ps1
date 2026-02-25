# Database Backup Script for HANHCHINHCONGQ5CHOLON
# Run this script daily with Windows Task Scheduler

param(
    [string]$BackupDir = "C:\Backups\HANHCHINHCONGQ5\database",
    [string]$DbHost = "localhost",
    [string]$DbPort = "5432",
    [string]$DbName = "cholon_db",
    [string]$DbUser = "postgres",
    [int]$RetentionDays = 30
)

# Create backup directory if not exists
if (!(Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host "[INFO] Created backup directory: $BackupDir"
}

# Generate timestamp and filename
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path $BackupDir "db_backup_$timestamp.backup"
$logFile = Join-Path $BackupDir "backup_log.txt"

Write-Host "============================================"
Write-Host "  DATABASE BACKUP - $(Get-Date)"
Write-Host "============================================"

# Check if pg_dump exists
$pgDump = Get-Command pg_dump -ErrorAction SilentlyContinue
if (!$pgDump) {
    $errorMsg = "[ERROR] pg_dump not found. Please add PostgreSQL bin to PATH."
    Write-Host $errorMsg -ForegroundColor Red
    Add-Content $logFile "$(Get-Date): $errorMsg"
    exit 1
}

# Perform backup
Write-Host "[INFO] Starting backup of database: $DbName"
Write-Host "[INFO] Backup file: $backupFile"

try {
    # Run pg_dump
    $startTime = Get-Date
    & pg_dump -U $DbUser -h $DbHost -p $DbPort -F c -b -v -f $backupFile $DbName 2>&1 | Out-Null
    $endTime = Get-Date
    $duration = $endTime - $startTime

    # Verify backup file
    if (Test-Path $backupFile) {
        $fileSize = (Get-Item $backupFile).Length / 1MB
        $successMsg = "[SUCCESS] Backup completed in $($duration.TotalSeconds) seconds. Size: $([math]::Round($fileSize, 2)) MB"
        Write-Host $successMsg -ForegroundColor Green
        Add-Content $logFile "$(Get-Date): $successMsg - $backupFile"
    } else {
        throw "Backup file was not created"
    }
} catch {
    $errorMsg = "[ERROR] Backup failed: $_"
    Write-Host $errorMsg -ForegroundColor Red
    Add-Content $logFile "$(Get-Date): $errorMsg"
    exit 1
}

# Cleanup old backups
Write-Host "[INFO] Cleaning up backups older than $RetentionDays days..."
$cutoffDate = (Get-Date).AddDays(-$RetentionDays)
$oldBackups = Get-ChildItem $BackupDir -Filter "db_backup_*.backup" | 
    Where-Object { $_.LastWriteTime -lt $cutoffDate }

if ($oldBackups.Count -gt 0) {
    foreach ($old in $oldBackups) {
        Remove-Item $old.FullName -Force
        Write-Host "[INFO] Deleted old backup: $($old.Name)"
        Add-Content $logFile "$(Get-Date): Deleted old backup - $($old.Name)"
    }
} else {
    Write-Host "[INFO] No old backups to delete"
}

# Summary
Write-Host ""
Write-Host "============================================"
Write-Host "  BACKUP SUMMARY"
Write-Host "============================================"
$allBackups = Get-ChildItem $BackupDir -Filter "db_backup_*.backup"
Write-Host "Total backups: $($allBackups.Count)"
Write-Host "Total size: $([math]::Round(($allBackups | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB"
Write-Host "Latest backup: $backupFile"
Write-Host "============================================"
