# Setup Windows Task Scheduler for Automated Backups
# Run this script once to configure scheduled tasks

param(
    [string]$ScriptDir = "C:\Users\Per\Desktop\HANHCHINHCONGQ5CHOLON\scripts",
    [switch]$Remove  # Use -Remove to uninstall scheduled tasks
)

$taskPrefix = "HCQQ5_Backup"

$tasks = @(
    @{
        Name = "${taskPrefix}_Daily_Database"
        Description = "Daily database backup at 2:00 AM"
        Script = "backup_database.ps1"
        Schedule = "Daily"
        Time = "02:00"
    },
    @{
        Name = "${taskPrefix}_Weekly_Project"
        Description = "Weekly full project backup on Sunday at 3:00 AM"
        Script = "backup_project.ps1"
        Schedule = "Weekly"
        DayOfWeek = "Sunday"
        Time = "03:00"
    },
    @{
        Name = "${taskPrefix}_Daily_Config"
        Description = "Daily config backup at 2:30 AM"
        Script = "backup_config.ps1"
        Schedule = "Daily"
        Time = "02:30"
    },
    @{
        Name = "${taskPrefix}_Hourly_HealthCheck"
        Description = "Hourly backup health check"
        Script = "check_backup_health.ps1"
        Schedule = "Hourly"
        Interval = 6  # Every 6 hours
    }
)

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        BACKUP SCHEDULER SETUP - HANH CHINH CONG Q5          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($Remove) {
    Write-Host "Removing scheduled tasks..." -ForegroundColor Yellow
    foreach ($task in $tasks) {
        $existing = Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue
        if ($existing) {
            Unregister-ScheduledTask -TaskName $task.Name -Confirm:$false
            Write-Host "  ✓ Removed: $($task.Name)" -ForegroundColor Green
        } else {
            Write-Host "  - Not found: $($task.Name)" -ForegroundColor Gray
        }
    }
    Write-Host ""
    Write-Host "All scheduled tasks removed." -ForegroundColor Green
    exit 0
}

Write-Host "Creating scheduled tasks..." -ForegroundColor Yellow
Write-Host ""

foreach ($task in $tasks) {
    $scriptPath = Join-Path $ScriptDir $task.Script
    
    # Check if script exists
    if (!(Test-Path $scriptPath)) {
        Write-Host "  ⚠️  Script not found: $($task.Script)" -ForegroundColor Red
        continue
    }
    
    # Remove existing task if any
    $existing = Get-ScheduledTask -TaskName $task.Name -ErrorAction SilentlyContinue
    if ($existing) {
        Unregister-ScheduledTask -TaskName $task.Name -Confirm:$false
    }
    
    # Create action
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`"" `
        -WorkingDirectory $ScriptDir
    
    # Create trigger based on schedule
    switch ($task.Schedule) {
        "Daily" {
            $trigger = New-ScheduledTaskTrigger -Daily -At $task.Time
        }
        "Weekly" {
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $task.DayOfWeek -At $task.Time
        }
        "Hourly" {
            $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours $task.Interval)
        }
    }
    
    # Create settings
    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -DontStopOnIdleEnd `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -ExecutionTimeLimit (New-TimeSpan -Hours 2)
    
    # Register task
    try {
        Register-ScheduledTask `
            -TaskName $task.Name `
            -Description $task.Description `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -RunLevel Highest `
            -User "SYSTEM" | Out-Null
        
        Write-Host "  ✓ Created: $($task.Name)" -ForegroundColor Green
        Write-Host "    Schedule: $($task.Schedule) at $($task.Time)" -ForegroundColor Gray
    } catch {
        Write-Host "  ⚠️  Failed to create: $($task.Name)" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    SETUP COMPLETE                            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Scheduled Tasks Created:" -ForegroundColor Yellow
Write-Host "  • Daily Database Backup: 2:00 AM" 
Write-Host "  • Daily Config Backup: 2:30 AM"
Write-Host "  • Weekly Project Backup: Sunday 3:00 AM"
Write-Host "  • Health Check: Every 6 hours"
Write-Host ""
Write-Host "To view tasks: taskschd.msc" -ForegroundColor Cyan
Write-Host "To remove tasks: .\setup_scheduler.ps1 -Remove" -ForegroundColor Cyan
Write-Host ""
