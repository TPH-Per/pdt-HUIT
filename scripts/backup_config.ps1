# Configuration Files Backup Script
# Backs up all important configuration files

param(
    [string]$SourceDir = "C:\Users\Per\Desktop\HANHCHINHCONGQ5CHOLON",
    [string]$BackupDir = "C:\Backups\HANHCHINHCONGQ5\config",
    [int]$RetentionDays = 30
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFolder = Join-Path $BackupDir $timestamp

# Create backup directory
if (!(Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
}

Write-Host "============================================"
Write-Host "  CONFIG BACKUP - $(Get-Date)"
Write-Host "============================================"

# Define config files to backup
$configFiles = @(
    # Backend configs
    @{ Source = "backend\src\main\resources\application.properties"; Dest = "backend\" },
    @{ Source = "backend\src\main\resources\application-dev.properties"; Dest = "backend\" },
    @{ Source = "backend\src\main\resources\application-prod.properties"; Dest = "backend\" },
    @{ Source = "backend\pom.xml"; Dest = "backend\" },
    
    # Client configs
    @{ Source = "client\.env"; Dest = "client\" },
    @{ Source = "client\.env.local"; Dest = "client\" },
    @{ Source = "client\.env.production"; Dest = "client\" },
    @{ Source = "client\vite.config.ts"; Dest = "client\" },
    @{ Source = "client\package.json"; Dest = "client\" },
    @{ Source = "client\tailwind.config.js"; Dest = "client\" },
    
    # AdminStaff configs
    @{ Source = "AdminStaff\.env"; Dest = "AdminStaff\" },
    @{ Source = "AdminStaff\.env.local"; Dest = "AdminStaff\" },
    @{ Source = "AdminStaff\.env.production"; Dest = "AdminStaff\" },
    @{ Source = "AdminStaff\vite.config.ts"; Dest = "AdminStaff\" },
    @{ Source = "AdminStaff\package.json"; Dest = "AdminStaff\" },
    @{ Source = "AdminStaff\tailwind.config.js"; Dest = "AdminStaff\" },
    
    # Database migrations
    @{ Source = "backend\src\main\resources\db\migration\*.sql"; Dest = "migrations\" }
)

$backedUp = 0
$skipped = 0

foreach ($config in $configFiles) {
    $sourcePath = Join-Path $SourceDir $config.Source
    $destPath = Join-Path $backupFolder $config.Dest
    
    # Create destination directory
    if (!(Test-Path $destPath)) {
        New-Item -ItemType Directory -Path $destPath -Force | Out-Null
    }
    
    # Check if source exists (supports wildcards)
    $files = Get-ChildItem $sourcePath -ErrorAction SilentlyContinue
    
    if ($files) {
        foreach ($file in $files) {
            Copy-Item $file.FullName $destPath -Force
            Write-Host "[OK] $($config.Source)" -ForegroundColor Green
            $backedUp++
        }
    } else {
        Write-Host "[SKIP] $($config.Source) (not found)" -ForegroundColor Yellow
        $skipped++
    }
}

# Create a zip archive
$zipFile = Join-Path $BackupDir "config_backup_$timestamp.zip"
Compress-Archive -Path "$backupFolder\*" -DestinationPath $zipFile -CompressionLevel Optimal -Force

# Remove the folder, keep only zip
Remove-Item $backupFolder -Recurse -Force

# Cleanup old backups
$cutoffDate = (Get-Date).AddDays(-$RetentionDays)
Get-ChildItem $BackupDir -Filter "config_backup_*.zip" | 
    Where-Object { $_.LastWriteTime -lt $cutoffDate } | 
    Remove-Item -Force

Write-Host ""
Write-Host "============================================"
Write-Host "  SUMMARY"
Write-Host "============================================"
Write-Host "  Files backed up: $backedUp"
Write-Host "  Files skipped: $skipped"
Write-Host "  Archive: $zipFile"
Write-Host "============================================"
