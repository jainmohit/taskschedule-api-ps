# Enhanced PowerShell Script with Time Parameter and 10-minute scheduling
# Includes multiple time format options and parameter handling

# Import required modules
Import-Module AWS.Tools.SecretsManager
Import-Module AWS.Tools.CloudWatchLogs

# Configuration
$SecretName = "api-credentials"
$LogGroupName = "/aws/ec2/api-scheduler"
$LogStreamName = "api-calls-$(Get-Date -Format 'yyyy-MM-dd')"
$Region = "us-east-1"
$TimeOffsetMinutes = 10

# Function to write logs to CloudWatch
function Write-CloudWatchLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $logEvent = @{
        timestamp = $timestamp
        message = "[$Level] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    }
    
    try {
        # Create log group if it doesn't exist
        try {
            Get-CWLLogGroup -LogGroupNamePrefix $LogGroupName -Region $Region | Out-Null
        }
        catch {
            New-CWLLogGroup -LogGroupName $LogGroupName -Region $Region
            Write-Host "Created log group: $LogGroupName"
        }
        
        # Create log stream if it doesn't exist
        try {
            Get-CWLLogStream -LogGroupName $LogGroupName -LogStreamNamePrefix $LogStreamName -Region $Region | Out-Null
        }
        catch {
            New-CWLLogStream -LogGroupName $LogGroupName -LogStreamName $LogStreamName -Region $Region
            Write-Host "Created log stream: $LogStreamName"
        }
        
        # Send log event
        Write-CWLLogEvent -LogGroupName $LogGroupName -LogStreamName $LogStreamName -LogEvent $logEvent -Region $Region
        Write-Host $logEvent.message
    }
    catch {
        Write-Error "Failed to write to CloudWatch: $_"
        Write-Host $logEvent.message
    }
}

# Function to get credentials from AWS Secrets Manager
function Get-ApiCredentials {
    try {
        Write-CloudWatchLog "Retrieving credentials from AWS Secrets Manager"
        $secret = Get-SECSecretValue -SecretId $SecretName -Region $Region
        $secretData = $secret.SecretString | ConvertFrom-Json
        
        return @{
            ApiUrl = $secretData.api_url
            ClientId = $secretData.client_id
            ClientSecret = $secretData.client_secret
            TokenEndpoint = $secretData.token_endpoint
            DataEndpoint = $secretData.data_endpoint
            TimeParameterName = $secretData.time_parameter_name ?? "timestamp"
            TimeFormat = $secretData.time_format ?? "iso8601"
        }
    }
    catch {
        Write-CloudWatchLog "Failed to retrieve credentials: $_" "ERROR"
        throw
    }
}

# Function to format time parameter based on API requirements
function Format-TimeParameter {
    param(
        [DateTime]$DateTime,
        [string]$Format
    )
    
    switch ($Format.ToLower()) {
        "iso8601" { 
            return $DateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
        "unix" { 
            return [DateTimeOffset]::new($DateTime).ToUnixTimeSeconds()
        }
        "unixmilli" { 
            return [DateTimeOffset]::new($DateTime).ToUnixTimeMilliseconds()
        }
        "standard" { 
            return $DateTime.ToString("yyyy-MM-dd HH:mm:ss")
        }
        "utc" { 
            return $DateTime.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
        }
        "custom" { 
            return $DateTime.ToString("yyyyMMddHHmmss")
        }
        default { 
            return $DateTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
    }
}

# Function to generate bearer token
function Get-BearerToken {
    param(
        [hashtable]$Credentials
    )
    
    try {
        Write-CloudWatchLog "Generating bearer token"
        
        $tokenBody = @{
            grant_type = "client_credentials"
            client_id = $Credentials.ClientId
            client_secret = $Credentials.ClientSecret
        }
        
        $tokenHeaders = @{
            "Content-Type" = "application/x-www-form-urlencoded"
        }
        
        $response = Invoke-RestMethod -Uri $Credentials.TokenEndpoint -Method POST -Body $tokenBody -Headers $tokenHeaders
        
        Write-CloudWatchLog "Bearer token generated successfully"
        return $response.access_token
    }
    catch {
        Write-CloudWatchLog "Failed to generate bearer token: $_" "ERROR"
        throw
    }
}

# Function to call API endpoint with time parameter
function Invoke-ApiEndpoint {
    param(
        [string]$Token,
        [hashtable]$Credentials
    )
    
    try {
        # Calculate time parameter (current time minus specified minutes)
        $currentTime = Get-Date
        $parameterTime = $currentTime.AddMinutes(-$TimeOffsetMinutes)
        
        # Format time parameter based on API requirements
        $formattedTime = Format-TimeParameter -DateTime $parameterTime -Format $Credentials.TimeFormat
        
        Write-CloudWatchLog "Calling API endpoint: $($Credentials.DataEndpoint) with $($Credentials.TimeParameterName): $formattedTime"
        
        $headers = @{
            "Authorization" = "Bearer $Token"
            "Content-Type" = "application/json"
        }
        
        # Build URL with time parameter
        $separator = if ($Credentials.DataEndpoint.Contains("?")) { "&" } else { "?" }
        $fullUrl = "$($Credentials.DataEndpoint)$separator$($Credentials.TimeParameterName)=$formattedTime"
        
        Write-CloudWatchLog "Full API URL: $fullUrl"
        
        $response = Invoke-RestMethod -Uri $fullUrl -Method GET -Headers $headers
        
        Write-CloudWatchLog "API call successful. Response received for time: $formattedTime"
        return @{
            Data = $response
            RequestTime = $currentTime
            ParameterTime = $parameterTime
            FormattedTime = $formattedTime
        }
    }
    catch {
        Write-CloudWatchLog "Failed to call API endpoint: $_" "ERROR"
        throw
    }
}

# Function to process and log API response
function Process-ApiResponse {
    param(
        [object]$ResponseData
    )
    
    try {
        $response = $ResponseData.Data
        
        # Convert response to JSON for logging
        $responseJson = $response | ConvertTo-Json -Depth 10 -Compress
        
        # Log the response data with timing information
        Write-CloudWatchLog "API Response for parameter time $($ResponseData.FormattedTime): $responseJson"
        
        # Log timing information
        Write-CloudWatchLog "Request executed at: $($ResponseData.RequestTime)"
        Write-CloudWatchLog "Parameter time used: $($ResponseData.ParameterTime) (formatted as: $($ResponseData.FormattedTime))"
        
        # Process response based on type
        if ($response -is [array]) {
            Write-CloudWatchLog "Processed array response with $($response.Count) items"
            
            # Log summary statistics if applicable
            if ($response.Count -gt 0 -and $response[0] -is [hashtable]) {
                $sampleKeys = ($response[0].Keys | Select-Object -First 5) -join ", "
                Write-CloudWatchLog "Sample response keys: $sampleKeys"
            }
        }
        elseif ($response -is [hashtable] -or $response.GetType().Name -eq "PSCustomObject") {
            $properties = ($response | Get-Member -MemberType Properties).Count
            Write-CloudWatchLog "Processed object response with $properties properties"
        }
        else {
            Write-CloudWatchLog "Processed response of type: $($response.GetType().Name)"
        }
        
        return @{
            Status = "Success"
            ItemCount = if ($response -is [array]) { $response.Count } else { 1 }
            ParameterTime = $ResponseData.FormattedTime
        }
    }
    catch {
        Write-CloudWatchLog "Failed to process API response: $_" "ERROR"
        throw
    }
}

# Main execution function
function Start-ApiSchedulerTask {
    try {
        Write-CloudWatchLog "Starting API Scheduler Task (10-minute interval)" "INFO"
        
        # Step 1: Get credentials from AWS Secrets Manager
        $credentials = Get-ApiCredentials
        
        # Step 2: Generate bearer token
        $bearerToken = Get-BearerToken -Credentials $credentials
        
        # Step 3: Call API endpoint with time parameter
        $apiResponse = Invoke-ApiEndpoint -Token $bearerToken -Credentials $credentials
        
        # Step 4: Process and log response
        $processResult = Process-ApiResponse -ResponseData $apiResponse
        
        Write-CloudWatchLog "API Scheduler Task completed successfully" "INFO"
        
        return @{
            Status = "Success"
            Timestamp = Get-Date
            ParameterTime = $processResult.ParameterTime
            ResponseCount = $processResult.ItemCount
            NextRunTime = (Get-Date).AddMinutes(10)
        }
    }
    catch {
        Write-CloudWatchLog "API Scheduler Task failed: $_" "ERROR"
        return @{
            Status = "Failed"
            Timestamp = Get-Date
            Error = $_.Exception.Message
            NextRunTime = (Get-Date).AddMinutes(10)
        }
    }
}

# Execute the main function
$result = Start-ApiSchedulerTask

# Output final result
Write-Host "Task Result: $($result | ConvertTo-Json -Depth 2)"
