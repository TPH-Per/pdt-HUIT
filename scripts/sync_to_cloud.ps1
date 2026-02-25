# Cloud Sync Script - Sync backups to cloud storage
# Supports: Google Drive (via rclone), AWS S3, or local network share

param(
    [string]$SourceDir = "C:\Backups\HANHCHINHCONGQ5",
    [ValidateSet("rclone", "aws", "network")]
    [string]$Provider = "network",
    
    # For rclone (Google Drive, OneDrive, etc.)
    [string]$RcloneRemote = "gdrive:Backups/HANHCHINHCONGQ5",
    
    # For AWS S3
    [string]$S3Bucket = "your-bucket-name",
    [string]$S3Path = "backups/hanhchinhcongq5",
    
    # For network share
    [string]$NetworkPath = "\\backup-server\backups\HANHCHINHCONGQ5",
    
    [switch]$DryRun
)

$logFile = Join-Path $SourceDir "logs\cloud_sync_$(Get-Date -Format 'yyyyMMdd').log"

function Write-Log {
    param([string]$Message)
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
    Write-Host $entry
    Add-Content $logFile $entry
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              CLOUD SYNC - OFFSITE BACKUP                     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Log "[INFO] Starting cloud sync using provider: $Provider"
Write-Log "[INFO] Source: $SourceDir"

$startTime = Get-Date

try {
    switch ($Provider) {
        "rclone" {
            Write-Log "[INFO] Destination: $RcloneRemote"
            
            # Check if rclone is installed
            $rclone = Get-Command rclone -ErrorAction SilentlyContinue
            if (!$rclone) {
                throw "rclone not found. Please install from https://rclone.org/"
            }
            
            # Sync command
            $args = @("sync", $SourceDir, $RcloneRemote, "-v", "--progress")
            if ($DryRun) { $args += "--dry-run" }
            
            & rclone @args
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "[SUCCESS] Sync completed successfully"
            } else {
                throw "rclone returned error code: $LASTEXITCODE"
            }
        }
        
        "aws" {
            Write-Log "[INFO] Destination: s3://$S3Bucket/$S3Path"
            
            # Check if AWS CLI is installed
            $aws = Get-Command aws -ErrorAction SilentlyContinue
            if (!$aws) {
                throw "AWS CLI not found. Please install from https://aws.amazon.com/cli/"
            }
            
            # Sync command
            $dest = "s3://$S3Bucket/$S3Path"
            $args = @("s3", "sync", $SourceDir, $dest, "--delete")
            if ($DryRun) { $args += "--dryrun" }
            
            & aws @args
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "[SUCCESS] Sync completed successfully"
            } else {
                throw "AWS CLI returned error code: $LASTEXITCODE"
            }
        }
        
        "network" {
            Write-Log "[INFO] Destination: $NetworkPath"
            
            # Check if network path is accessible
            if (!(Test-Path $NetworkPath)) {
                # Try to create it
                try {
                    New-Item -ItemType Directory -Path $NetworkPath -Force | Out-Null
                } catch {
                    throw "Cannot access network path: $NetworkPath"
                }
            }
            
            # Use robocopy for reliable copy
            $args = @($SourceDir, $NetworkPath, "/MIR", "/R:3", "/W:5", "/MT:8", "/NP")
            if ($DryRun) { $args += "/L" }
            
            Write-Log "[INFO] Running robocopy..."
            $output = & robocopy @args
            
            # Robocopy exit codes: 0-3 = success, 4+ = error
            if ($LASTEXITCODE -le 3) {
                Write-Log "[SUCCESS] Sync completed successfully"
            } else {
                throw "Robocopy returned error code: $LASTEXITCODE"
            }
        }
    }
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    SYNC COMPLETE                             ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Log "[INFO] Duration: $([math]::Round($duration.TotalMinutes, 2)) minutes"
    
    exit 0
    
} catch {
    Write-Log "[ERROR] Sync failed: $_"
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                    SYNC FAILED                               ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
