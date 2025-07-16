# Script to test different time format options for your API

$testTime = (Get-Date).AddMinutes(-10)

Write-Host "Testing different time formats for API parameter:"
Write-Host "Base time (10 minutes ago): $testTime"
Write-Host ""

# Test different formats
$formats = @{
    "ISO8601" = $testTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    "Unix Timestamp" = [DateTimeOffset]::new($testTime).ToUnixTimeSeconds()
    "Unix Milliseconds" = [DateTimeOffset]::new($testTime).ToUnixTimeMilliseconds()
    "Standard" = $testTime.ToString("yyyy-MM-dd HH:mm:ss")
    "UTC Standard" = $testTime.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
    "Custom" = $testTime.ToString("yyyyMMddHHmmss")
    "RFC3339" = $testTime.ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss'Z'")
}

foreach ($format in $formats.GetEnumerator()) {
    Write-Host "$($format.Key): $($format.Value)"
}

Write-Host ""
Write-Host "Update your AWS Secret with the appropriate 'time_format' value:"
Write-Host "- iso8601, unix, unixmilli, standard, utc, custom"
