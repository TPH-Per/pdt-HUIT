# Full Project Backup Script for HANHCHINHCONGQ5CHOLON
# Backs up entire project excluding node_modules, target, dist, .git

param(
    [string]$SourceDir = "C:\Users\Per\Desktop\HANHCHINHCONGQ5CHOLON",
    [string]$BackupDir = "C:\Backups\HANHCHINHCONGQ5\project",
    [int]$RetentionDays = 14
)

# Create backup directory if not exists
if (!(Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host "[INFO] Created backup directory: $BackupDir"
}

# Generate timestamp and filename
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path $BackupDir "project_backup_$timestamp.zip"
$tempDir = Join-Path $env:TEMP "project_backup_$timestamp"
$logFile = Join-Path $BackupDir "project_backup_log.txt"

Write-Host "============================================"
Write-Host "  PROJECT BACKUP - $(Get-Date)"
Write-Host "============================================"
Write-Host "[INFO] Source: $SourceDir"
Write-Host "[INFO] Destination: $backupFile"

try {
    $startTime = Get-Date

    # Create temp directory
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    # Define exclusions
    $excludeDirs = @("node_modules", "target", "dist", ".git", ".idea", ".vscode", "__pycache__")
    $excludePatterns = @("*.log", "*.tmp", "*.bak")

    # Copy files excluding specified directories
    Write-Host "[INFO] Copying files (excluding node_modules, target, dist, .git)..."
    
    $robocopyArgs = @(
        $SourceDir, $tempDir,
        "/E", "/R:1", "/W:1",
        "/XD"
    ) + $excludeDirs + @("/XF") + $excludePatterns

    & robocopy @robocopyArgs | Out-Null

    # Create zip archive
    Write-Host "[INFO] Creating zip archive..."
    Compress-Archive -Path "$tempDir\*" -DestinationPath $backupFile -CompressionLevel Optimal -Force

    $endTime = Get-Date
    $duration = $endTime - $startTime

    # Get file size
    $fileSize = (Get-Item $backupFile).Length / 1MB

    # Cleanup temp directory
    Remove-Item $tempDir -Recurse -Force

    $successMsg = "[SUCCESS] Backup completed in $([math]::Round($duration.TotalMinutes, 2)) minutes. Size: $([math]::Round($fileSize, 2)) MB"
    Write-Host $successMsg -ForegroundColor Green
    Add-Content $logFile "$(Get-Date): $successMsg - $backupFile"

} catch {
    $errorMsg = "[ERROR] Backup failed: $_"
    Write-Host $errorMsg -ForegroundColor Red
    Add-Content $logFile "$(Get-Date): $errorMsg"
    
    # Cleanup temp directory on error
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    exit 1
}

# Cleanup old backups
Write-Host "[INFO] Cleaning up backups older than $RetentionDays days..."
$cutoffDate = (Get-Date).AddDays(-$RetentionDays)
$oldBackups = Get-ChildItem $BackupDir -Filter "project_backup_*.zip" | 
    Where-Object { $_.LastWriteTime -lt $cutoffDate }

if ($oldBackups.Count -gt 0) {
    foreach ($old in $oldBackups) {
        Remove-Item $old.FullName -Force
        Write-Host "[INFO] Deleted old backup: $($old.Name)"
        Add-Content $logFile "$(Get-Date): Deleted old backup - $($old.Name)"
    }
}

# Summary
Write-Host ""
Write-Host "============================================"
Write-Host "  BACKUP SUMMARY"
Write-Host "============================================"
$allBackups = Get-ChildItem $BackupDir -Filter "project_backup_*.zip"
Write-Host "Total backups: $($allBackups.Count)"
Write-Host "Total size: $([math]::Round(($allBackups | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB"
Write-Host "Latest backup: $backupFile"
Write-Host "============================================"
