# Manual execution script for testing the API scheduler without scheduled task

Write-Host "Manual API Scheduler Execution" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green

# Configuration for manual testing
$SecretName = "api-credentials"
$Region = "us-east-1"
$TimeOffsetMinutes = 10

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Secret Name: $SecretName"
Write-Host "  Region: $Region"
Write-Host "  Time Offset: $TimeOffsetMinutes minutes"
Write-Host ""

# Import required modules
try {
    Import-Module AWS.Tools.SecretsManager
    Import-Module AWS.Tools.CloudWatchLogs
    Write-Host "✓ AWS modules imported successfully" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to import AWS modules: $_" -ForegroundColor Red
    exit 1
}

# Calculate and display time parameter
$currentTime = Get-Date
$parameterTime = $currentTime.AddMinutes(-$TimeOffsetMinutes)
$formattedTime = $parameterTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

Write-Host "Time Information:" -ForegroundColor Yellow
Write-Host "  Current Time: $currentTime"
Write-Host "  Parameter Time: $parameterTime"
Write-Host "  Formatted Time: $formattedTime"
Write-Host ""

# Execute the main script
Write-Host "Executing API Scheduler..." -ForegroundColor Yellow
try {
    & ".\api-scheduler.ps1"
    Write-Host "✓ Manual execution completed" -ForegroundColor Green
}
catch {
    Write-Host "✗ Manual execution failed: $_" -ForegroundColor Red
}

Write-Host "`nManual execution finished!" -ForegroundColor Green
