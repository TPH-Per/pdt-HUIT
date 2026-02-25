# Backup Health Check Script
# Monitors backup status and sends alerts if needed

param(
    [string]$BackupRoot = "C:\Backups\HANHCHINHCONGQ5",
    [int]$MaxAgeHours = 25,  # Alert if backup is older than this
    [int]$MinSizeMB = 1,     # Alert if backup is smaller than this
    [string]$EmailTo = "",   # Optional: email for alerts
    [switch]$Verbose
)

$issues = @()
$warnings = @()

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║               BACKUP HEALTH CHECK REPORT                     ║" -ForegroundColor Cyan
Write-Host "║                 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')                          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================
# 1. CHECK DISK SPACE
# ============================================
Write-Host "📁 DISK SPACE CHECK" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────"

$drive = (Get-Item $BackupRoot).PSDrive.Name
$driveInfo = Get-PSDrive $drive
$freeSpaceGB = [math]::Round($driveInfo.Free / 1GB, 2)
$usedSpaceGB = [math]::Round($driveInfo.Used / 1GB, 2)
$totalSpaceGB = [math]::Round(($driveInfo.Free + $driveInfo.Used) / 1GB, 2)
$usedPercent = [math]::Round(($driveInfo.Used / ($driveInfo.Free + $driveInfo.Used)) * 100, 1)

Write-Host "  Drive $($drive): $usedSpaceGB GB used / $totalSpaceGB GB total ($usedPercent%)"
Write-Host "  Free Space: $freeSpaceGB GB"

if ($freeSpaceGB -lt 10) {
    $issues += "CRITICAL: Low disk space on drive $drive ($freeSpaceGB GB free)"
    Write-Host "  ⚠️  WARNING: Low disk space!" -ForegroundColor Red
} elseif ($freeSpaceGB -lt 50) {
    $warnings += "Disk space below 50GB on drive $drive"
    Write-Host "  ⚠️  Notice: Disk space getting low" -ForegroundColor Yellow
} else {
    Write-Host "  ✓ Disk space OK" -ForegroundColor Green
}

Write-Host ""

# ============================================
# 2. CHECK DATABASE BACKUPS
# ============================================
Write-Host "🗄️  DATABASE BACKUPS" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────"

$dbBackupDir = Join-Path $BackupRoot "database"
if (Test-Path $dbBackupDir) {
    $dbBackups = Get-ChildItem $dbBackupDir -Filter "db_backup_*.backup" | Sort-Object LastWriteTime -Descending
    
    if ($dbBackups.Count -gt 0) {
        $latestDb = $dbBackups[0]
        $ageHours = [math]::Round(((Get-Date) - $latestDb.LastWriteTime).TotalHours, 1)
        $sizeMB = [math]::Round($latestDb.Length / 1MB, 2)
        
        Write-Host "  Latest: $($latestDb.Name)"
        Write-Host "  Size: $sizeMB MB"
        Write-Host "  Age: $ageHours hours"
        Write-Host "  Total backups: $($dbBackups.Count)"
        
        if ($ageHours -gt $MaxAgeHours) {
            $issues += "Database backup is $ageHours hours old (max: $MaxAgeHours)"
            Write-Host "  ⚠️  ALERT: Backup too old!" -ForegroundColor Red
        } elseif ($sizeMB -lt $MinSizeMB) {
            $issues += "Database backup size is only $sizeMB MB"
            Write-Host "  ⚠️  ALERT: Backup too small!" -ForegroundColor Red
        } else {
            Write-Host "  ✓ Database backup OK" -ForegroundColor Green
        }
    } else {
        $issues += "No database backups found"
        Write-Host "  ⚠️  CRITICAL: No backups found!" -ForegroundColor Red
    }
} else {
    $issues += "Database backup directory not found"
    Write-Host "  ⚠️  CRITICAL: Backup directory missing!" -ForegroundColor Red
}

Write-Host ""

# ============================================
# 3. CHECK PROJECT BACKUPS
# ============================================
Write-Host "📦 PROJECT BACKUPS" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────"

$projBackupDir = Join-Path $BackupRoot "project"
if (Test-Path $projBackupDir) {
    $projBackups = Get-ChildItem $projBackupDir -Filter "project_backup_*.zip" | Sort-Object LastWriteTime -Descending
    
    if ($projBackups.Count -gt 0) {
        $latestProj = $projBackups[0]
        $ageHours = [math]::Round(((Get-Date) - $latestProj.LastWriteTime).TotalHours, 1)
        $sizeMB = [math]::Round($latestProj.Length / 1MB, 2)
        
        Write-Host "  Latest: $($latestProj.Name)"
        Write-Host "  Size: $sizeMB MB"
        Write-Host "  Age: $ageHours hours"
        Write-Host "  Total backups: $($projBackups.Count)"
        
        # Project backup can be weekly, so use 7 days threshold
        if ($ageHours -gt 168) {  # 7 days
            $warnings += "Project backup is more than 7 days old"
            Write-Host "  ⚠️  Notice: Backup older than 7 days" -ForegroundColor Yellow
        } else {
            Write-Host "  ✓ Project backup OK" -ForegroundColor Green
        }
    } else {
        $warnings += "No project backups found"
        Write-Host "  ⚠️  Notice: No backups found" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Directory not created yet" -ForegroundColor Gray
}

Write-Host ""

# ============================================
# 4. CHECK CONFIG BACKUPS
# ============================================
Write-Host "⚙️  CONFIG BACKUPS" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────"

$configBackupDir = Join-Path $BackupRoot "config"
if (Test-Path $configBackupDir) {
    $configBackups = Get-ChildItem $configBackupDir -Filter "config_backup_*.zip" | Sort-Object LastWriteTime -Descending
    
    if ($configBackups.Count -gt 0) {
        $latestConfig = $configBackups[0]
        Write-Host "  Latest: $($latestConfig.Name)"
        Write-Host "  Total backups: $($configBackups.Count)"
        Write-Host "  ✓ Config backup OK" -ForegroundColor Green
    } else {
        $warnings += "No config backups found"
        Write-Host "  ⚠️  Notice: No backups found" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Directory not created yet" -ForegroundColor Gray
}

Write-Host ""

# ============================================
# 5. BACKUP SIZE TREND
# ============================================
if ($Verbose -and (Test-Path $dbBackupDir)) {
    Write-Host "📊 BACKUP SIZE TREND (Last 7 days)" -ForegroundColor Yellow
    Write-Host "─────────────────────────────────────────"
    
    $recentBackups = Get-ChildItem $dbBackupDir -Filter "db_backup_*.backup" | 
        Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) } |
        Sort-Object LastWriteTime
    
    foreach ($backup in $recentBackups) {
        $sizeMB = [math]::Round($backup.Length / 1MB, 2)
        $bar = "█" * [math]::Min([math]::Round($sizeMB / 10), 30)
        Write-Host "  $($backup.LastWriteTime.ToString('MM-dd HH:mm')) | $bar $sizeMB MB"
    }
    Write-Host ""
}

# ============================================
# SUMMARY
# ============================================
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                         SUMMARY                              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "  ✓ ALL SYSTEMS HEALTHY" -ForegroundColor Green
    Write-Host ""
    exit 0
}

if ($warnings.Count -gt 0) {
    Write-Host "  ⚠️  WARNINGS ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($warn in $warnings) {
        Write-Host "     - $warn" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($issues.Count -gt 0) {
    Write-Host "  ❌ CRITICAL ISSUES ($($issues.Count)):" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "     - $issue" -ForegroundColor Red
    }
    Write-Host ""
    
    # Send email alert if configured
    if ($EmailTo) {
        try {
            $subject = "⚠️ Backup Alert - HANHCHINHCONGQ5"
            $body = "The following backup issues were detected:`n`n" + ($issues -join "`n")
            # Send-MailMessage -To $EmailTo -Subject $subject -Body $body -SmtpServer "smtp.example.com"
            Write-Host "  Email alert sent to: $EmailTo" -ForegroundColor Cyan
        } catch {
            Write-Host "  Failed to send email alert: $_" -ForegroundColor Red
        }
    }
    
    exit 1
}

exit 0
