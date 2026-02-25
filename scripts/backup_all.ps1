# Master Backup Script - Runs all backup tasks
# This is the main script to run for complete system backup

param(
    [switch]$DatabaseOnly,
    [switch]$ProjectOnly,
    [switch]$ConfigOnly,
    [switch]$SkipCloudSync,
    [string]$BackupRoot = "C:\Backups\HANHCHINHCONGQ5"
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $BackupRoot "logs\master_backup_$timestamp.log"

# Create directories
$dirs = @("$BackupRoot\database", "$BackupRoot\project", "$BackupRoot\config", "$BackupRoot\logs")
foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Write-Host $logEntry
    Add-Content $logFile $logEntry
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      MASTER BACKUP SCRIPT - HANH CHINH CONG Q5 CHOLON       ║" -ForegroundColor Cyan
Write-Host "║                    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')                        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$results = @{
    Database = $null
    Project = $null
    Config = $null
    CloudSync = $null
}

$startTime = Get-Date

# ============================================
# 1. DATABASE BACKUP
# ============================================
if (!$ProjectOnly -and !$ConfigOnly) {
    Write-Log "Starting Database Backup..."
    try {
        & "$scriptDir\backup_database.ps1" -BackupDir "$BackupRoot\database"
        $results.Database = "SUCCESS"
        Write-Log "Database backup completed successfully" "SUCCESS"
    } catch {
        $results.Database = "FAILED: $_"
        Write-Log "Database backup failed: $_" "ERROR"
    }
}

# ============================================
# 2. PROJECT BACKUP
# ============================================
if (!$DatabaseOnly -and !$ConfigOnly) {
    Write-Log "Starting Project Backup..."
    try {
        & "$scriptDir\backup_project.ps1" -BackupDir "$BackupRoot\project"
        $results.Project = "SUCCESS"
        Write-Log "Project backup completed successfully" "SUCCESS"
    } catch {
        $results.Project = "FAILED: $_"
        Write-Log "Project backup failed: $_" "ERROR"
    }
}

# ============================================
# 3. CONFIG BACKUP
# ============================================
if (!$DatabaseOnly -and !$ProjectOnly) {
    Write-Log "Starting Config Backup..."
    try {
        & "$scriptDir\backup_config.ps1" -BackupDir "$BackupRoot\config"
        $results.Config = "SUCCESS"
        Write-Log "Config backup completed successfully" "SUCCESS"
    } catch {
        $results.Config = "FAILED: $_"
        Write-Log "Config backup failed: $_" "ERROR"
    }
}

# ============================================
# 4. CLOUD SYNC (Optional)
# ============================================
if (!$SkipCloudSync) {
    Write-Log "Starting Cloud Sync..."
    try {
        if (Test-Path "$scriptDir\sync_to_cloud.ps1") {
            & "$scriptDir\sync_to_cloud.ps1" -SourceDir $BackupRoot
            $results.CloudSync = "SUCCESS"
            Write-Log "Cloud sync completed successfully" "SUCCESS"
        } else {
            $results.CloudSync = "SKIPPED (script not found)"
            Write-Log "Cloud sync skipped - script not configured" "WARN"
        }
    } catch {
        $results.CloudSync = "FAILED: $_"
        Write-Log "Cloud sync failed: $_" "ERROR"
    }
}

$endTime = Get-Date
$duration = $endTime - $startTime

# ============================================
# SUMMARY
# ============================================
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                      BACKUP SUMMARY                          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$successCount = 0
$failCount = 0

foreach ($task in $results.GetEnumerator()) {
    if ($null -eq $task.Value) { continue }
    
    $status = $task.Value
    $color = if ($status -eq "SUCCESS") { "Green"; $successCount++ } 
             elseif ($status -like "FAILED*") { "Red"; $failCount++ } 
             else { "Yellow" }
    
    Write-Host "  $($task.Key): " -NoNewline
    Write-Host $status -ForegroundColor $color
}

Write-Host ""
Write-Host "  Total Duration: $([math]::Round($duration.TotalMinutes, 2)) minutes"
Write-Host "  Log File: $logFile"
Write-Host ""

# Exit with error code if any backup failed
if ($failCount -gt 0) {
    Write-Log "Backup completed with $failCount failure(s)" "ERROR"
    exit 1
} else {
    Write-Log "All backups completed successfully" "SUCCESS"
    exit 0
}
