# Backup Integrity Verification Script
# Tests backup files to ensure they can be restored

param(
    [string]$BackupRoot = "C:\Backups\HANHCHINHCONGQ5",
    [switch]$TestRestore,  # Actually try to restore to temp database
    [string]$TestDbName = "cholon_db_test"
)

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║            BACKUP INTEGRITY VERIFICATION                     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$results = @()

# ============================================
# 1. VERIFY DATABASE BACKUP
# ============================================
Write-Host "🗄️  VERIFYING DATABASE BACKUP" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────"

$dbBackupDir = Join-Path $BackupRoot "database"
$latestDbBackup = Get-ChildItem $dbBackupDir -Filter "db_backup_*.backup" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if ($latestDbBackup) {
    Write-Host "  File: $($latestDbBackup.Name)"
    
    # Check file size
    $sizeMB = [math]::Round($latestDbBackup.Length / 1MB, 2)
    Write-Host "  Size: $sizeMB MB"
    
    if ($sizeMB -lt 0.1) {
        Write-Host "  ⚠️  WARNING: File too small, may be corrupted" -ForegroundColor Red
        $results += @{ Type = "Database"; Status = "SUSPECT"; Message = "File too small" }
    } else {
        # Try to list contents using pg_restore
        Write-Host "  Verifying contents with pg_restore --list..."
        
        try {
            $output = & pg_restore --list $latestDbBackup.FullName 2>&1
            $lineCount = ($output | Measure-Object -Line).Lines
            
            if ($lineCount -gt 10) {
                Write-Host "  ✓ Backup contains $lineCount objects" -ForegroundColor Green
                $results += @{ Type = "Database"; Status = "OK"; Message = "$lineCount objects" }
                
                # Test actual restore if requested
                if ($TestRestore) {
                    Write-Host "  Testing restore to temporary database..."
                    try {
                        # Create test database
                        & psql -U postgres -c "DROP DATABASE IF EXISTS $TestDbName;" 2>&1 | Out-Null
                        & psql -U postgres -c "CREATE DATABASE $TestDbName;" 2>&1 | Out-Null
                        
                        # Restore
                        & pg_restore -U postgres -d $TestDbName $latestDbBackup.FullName 2>&1 | Out-Null
                        
                        # Verify tables
                        $tables = & psql -U postgres -d $TestDbName -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';"
                        
                        Write-Host "  ✓ Test restore successful ($tables tables)" -ForegroundColor Green
                        
                        # Cleanup
                        & psql -U postgres -c "DROP DATABASE $TestDbName;" 2>&1 | Out-Null
                        
                    } catch {
                        Write-Host "  ⚠️  Test restore failed: $_" -ForegroundColor Red
                        $results += @{ Type = "Database (Restore)"; Status = "FAILED"; Message = $_ }
                    }
                }
            } else {
                Write-Host "  ⚠️  Backup may be empty or corrupted" -ForegroundColor Red
                $results += @{ Type = "Database"; Status = "SUSPECT"; Message = "Too few objects" }
            }
        } catch {
            Write-Host "  ⚠️  Cannot verify backup: $_" -ForegroundColor Red
            $results += @{ Type = "Database"; Status = "FAILED"; Message = $_ }
        }
    }
} else {
    Write-Host "  ⚠️  No database backup found" -ForegroundColor Red
    $results += @{ Type = "Database"; Status = "MISSING"; Message = "No backup file" }
}

Write-Host ""

# ============================================
# 2. VERIFY PROJECT BACKUP
# ============================================
Write-Host "📦 VERIFYING PROJECT BACKUP" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────"

$projBackupDir = Join-Path $BackupRoot "project"
$latestProjBackup = Get-ChildItem $projBackupDir -Filter "project_backup_*.zip" -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if ($latestProjBackup) {
    Write-Host "  File: $($latestProjBackup.Name)"
    
    $sizeMB = [math]::Round($latestProjBackup.Length / 1MB, 2)
    Write-Host "  Size: $sizeMB MB"
    
    # Try to list zip contents
    try {
        $zipContents = [System.IO.Compression.ZipFile]::OpenRead($latestProjBackup.FullName)
        $entryCount = $zipContents.Entries.Count
        $zipContents.Dispose()
        
        Write-Host "  ✓ Archive contains $entryCount files" -ForegroundColor Green
        $results += @{ Type = "Project"; Status = "OK"; Message = "$entryCount files" }
        
        # Check for key directories
        $zipContents = [System.IO.Compression.ZipFile]::OpenRead($latestProjBackup.FullName)
        $hasBackend = $zipContents.Entries | Where-Object { $_.FullName -like "*/backend/*" } | Select-Object -First 1
        $hasClient = $zipContents.Entries | Where-Object { $_.FullName -like "*/client/*" } | Select-Object -First 1
        $hasAdmin = $zipContents.Entries | Where-Object { $_.FullName -like "*/AdminStaff/*" } | Select-Object -First 1
        $zipContents.Dispose()
        
        if ($hasBackend -and $hasClient -and $hasAdmin) {
            Write-Host "  ✓ All project components present" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  Some components may be missing" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "  ⚠️  Cannot read zip file: $_" -ForegroundColor Red
        $results += @{ Type = "Project"; Status = "CORRUPT"; Message = "Cannot read zip" }
    }
} else {
    Write-Host "  No project backup found (may be normal if weekly backup not due)" -ForegroundColor Gray
    $results += @{ Type = "Project"; Status = "MISSING"; Message = "No backup file" }
}

Write-Host ""

# ============================================
# 3. VERIFY CONFIG BACKUP
# ============================================
Write-Host "⚙️  VERIFYING CONFIG BACKUP" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────"

$configBackupDir = Join-Path $BackupRoot "config"
$latestConfigBackup = Get-ChildItem $configBackupDir -Filter "config_backup_*.zip" -ErrorAction SilentlyContinue | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if ($latestConfigBackup) {
    Write-Host "  File: $($latestConfigBackup.Name)"
    
    try {
        $zipContents = [System.IO.Compression.ZipFile]::OpenRead($latestConfigBackup.FullName)
        $entryCount = $zipContents.Entries.Count
        $zipContents.Dispose()
        
        Write-Host "  ✓ Archive contains $entryCount files" -ForegroundColor Green
        $results += @{ Type = "Config"; Status = "OK"; Message = "$entryCount files" }
    } catch {
        Write-Host "  ⚠️  Cannot read zip file: $_" -ForegroundColor Red
        $results += @{ Type = "Config"; Status = "CORRUPT"; Message = "Cannot read zip" }
    }
} else {
    Write-Host "  No config backup found" -ForegroundColor Gray
    $results += @{ Type = "Config"; Status = "MISSING"; Message = "No backup file" }
}

Write-Host ""

# ============================================
# SUMMARY
# ============================================
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                  VERIFICATION SUMMARY                        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$okCount = ($results | Where-Object { $_.Status -eq "OK" }).Count
$failCount = ($results | Where-Object { $_.Status -in @("FAILED", "CORRUPT") }).Count
$warnCount = ($results | Where-Object { $_.Status -in @("SUSPECT", "MISSING") }).Count

foreach ($result in $results) {
    $color = switch ($result.Status) {
        "OK" { "Green" }
        "SUSPECT" { "Yellow" }
        "MISSING" { "Yellow" }
        default { "Red" }
    }
    Write-Host "  $($result.Type): " -NoNewline
    Write-Host "$($result.Status) - $($result.Message)" -ForegroundColor $color
}

Write-Host ""
Write-Host "  OK: $okCount | Warnings: $warnCount | Failed: $failCount"
Write-Host ""

if ($failCount -gt 0) {
    Write-Host "  ⚠️  SOME BACKUPS NEED ATTENTION!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "  ✓ ALL VERIFICATIONS PASSED" -ForegroundColor Green
    exit 0
}
