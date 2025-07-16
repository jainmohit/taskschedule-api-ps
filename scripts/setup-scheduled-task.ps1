# Script to set up Windows Scheduled Task for the API Scheduler (10-minute intervals)

# Configuration
$TaskName = "API-Scheduler-Task-10min"
$ScriptPath = "C:\Scripts\api-scheduler.ps1"
$LogPath = "C:\Scripts\Logs"

# Create logs directory if it doesn't exist
if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force
    Write-Host "Created logs directory: $LogPath"
}

# Create the scheduled task action
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" > `"$LogPath\api-scheduler-$(Get-Date -Format 'yyyyMMdd').log`" 2>&1"

# Create the scheduled task trigger (runs every 10 minutes)
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 10)

# Create the scheduled task settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

# Create the scheduled task principal (run as SYSTEM or specify user)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the scheduled task
try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Force
    Write-Host "Scheduled task '$TaskName' created successfully"
    Write-Host "Task will run every 10 minutes starting in 1 minute"
    
    # Display task schedule information
    Write-Host "Next run times:"
    $nextRuns = @()
    $nextTime = (Get-Date).AddMinutes(1)
    for ($i = 0; $i -lt 5; $i++) {
        $nextRuns += $nextTime.ToString("yyyy-MM-dd HH:mm:ss")
        $nextTime = $nextTime.AddMinutes(10)
    }
    $nextRuns | ForEach-Object { Write-Host "  $_" }
    
    # Start the task immediately for testing
    Start-ScheduledTask -TaskName $TaskName
    Write-Host "Task started for immediate execution"
}
catch {
    Write-Error "Failed to create scheduled task: $_"
}

# Display task information
Write-Host "`nTask Details:"
Get-ScheduledTask -TaskName $TaskName | Format-List TaskName, State, LastRunTime, NextRunTime
