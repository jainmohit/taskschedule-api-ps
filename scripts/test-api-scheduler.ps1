# Test script to verify API scheduler functionality

Write-Host "Testing API Scheduler Components..." -ForegroundColor Green

# Test 1: Check AWS modules
Write-Host "`n1. Testing AWS Module Availability..." -ForegroundColor Yellow
try {
    Import-Module AWS.Tools.SecretsManager -ErrorAction Stop
    Import-Module AWS.Tools.CloudWatchLogs -ErrorAction Stop
    Write-Host "✓ AWS modules loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "✗ AWS modules not available: $_" -ForegroundColor Red
    Write-Host "Run install-dependencies.ps1 first" -ForegroundColor Yellow
}

# Test 2: Check time formatting
Write-Host "`n2. Testing Time Parameter Formatting..." -ForegroundColor Yellow
$testTime = (Get-Date).AddMinutes(-10)
Write-Host "Base time (10 minutes ago): $testTime"

$formats = @{
    "ISO8601" = $testTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    "Unix" = [DateTimeOffset]::new($testTime).ToUnixTimeSeconds()
    "UnixMilli" = [DateTimeOffset]::new($testTime).ToUnixTimeMilliseconds()
    "Standard" = $testTime.ToString("yyyy-MM-dd HH:mm:ss")
    "UTC" = $testTime.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
}

foreach ($format in $formats.GetEnumerator()) {
    Write-Host "  $($format.Key): $($format.Value)" -ForegroundColor Cyan
}

# Test 3: Check scheduled task
Write-Host "`n3. Checking Scheduled Task..." -ForegroundColor Yellow
try {
    $task = Get-ScheduledTask -TaskName "API-Scheduler-Task-10min" -ErrorAction Stop
    Write-Host "✓ Scheduled task exists" -ForegroundColor Green
    Write-Host "  State: $($task.State)" -ForegroundColor Cyan
    Write-Host "  Last Run: $($task.LastRunTime)" -ForegroundColor Cyan
    Write-Host "  Next Run: $($task.NextRunTime)" -ForegroundColor Cyan
}
catch {
    Write-Host "✗ Scheduled task not found" -ForegroundColor Red
    Write-Host "Run setup-scheduled-task.ps1 to create it" -ForegroundColor Yellow
}

# Test 4: Simulate URL building
Write-Host "`n4. Testing URL Parameter Building..." -ForegroundColor Yellow
$baseUrl = "https://api.example.com/data"
$paramName = "timestamp"
$timeValue = $testTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$separator = if ($baseUrl.Contains("?")) { "&" } else { "?" }
$fullUrl = "$baseUrl$separator$paramName=$timeValue"
Write-Host "Sample API URL: $fullUrl" -ForegroundColor Cyan

Write-Host "`nTest completed!" -ForegroundColor Green
