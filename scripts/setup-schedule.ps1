# Script to set up Windows Scheduled Task (5-minute intervals)

$TaskName = "API-Scheduler-5min"
$ScriptPath = "C:\Scripts\api-scheduler.ps1"

# Create the scheduled task action
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""

# Create the scheduled task trigger (runs every 5 minutes)
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5)

# Create the scheduled task settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Create the scheduled task principal
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the scheduled task
try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Force
    Write-Host "Scheduled task '$TaskName' created successfully"
    Write-Host "Task will run every 5 minutes"
    
    # Start immediately
    Start-ScheduledTask -TaskName $TaskName
    Write-Host "Task started"
}
catch {
    Write-Error "Failed to create scheduled task: $_"
}
