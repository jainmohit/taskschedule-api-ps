# PowerShell Script for API calls with time parameter (current time - 5 minutes)
# Runs every 5 minutes

# Import required modules
Import-Module AWS.Tools.SecretsManager

# Configuration
$SecretName = "api-credentials"
$Region = "us-east-1"
$TimeOffsetMinutes = 5

# Function to get credentials from AWS Secrets Manager
function Get-ApiCredentials {
    try {
        $secret = Get-SECSecretValue -SecretId $SecretName -Region $Region
        $secretData = $secret.SecretString | ConvertFrom-Json
        
        return @{
            ClientId = $secretData.client_id
            ClientSecret = $secretData.client_secret
            TokenEndpoint = $secretData.token_endpoint
            DataEndpoint = $secretData.data_endpoint
        }
    }
    catch {
        Write-Error "Failed to retrieve credentials: $_"
        throw
    }
}

# Function to generate bearer token
function Get-BearerToken {
    param([hashtable]$Credentials)
    
    try {
        $tokenBody = @{
            grant_type = "client_credentials"
            client_id = $Credentials.ClientId
            client_secret = $Credentials.ClientSecret
        }
        
        $tokenHeaders = @{
            "Content-Type" = "application/x-www-form-urlencoded"
        }
        
        $response = Invoke-RestMethod -Uri $Credentials.TokenEndpoint -Method POST -Body $tokenBody -Headers $tokenHeaders
        return $response.access_token
    }
    catch {
        Write-Error "Failed to generate bearer token: $_"
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
        # Calculate time parameter (current time minus 5 minutes)
        $parameterTime = (Get-Date).AddMinutes(-$TimeOffsetMinutes)
        $formattedTime = $parameterTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        
        $headers = @{
            "Authorization" = "Bearer $Token"
            "Content-Type" = "application/json"
        }
        
        # Build URL with time parameter
        $separator = if ($Credentials.DataEndpoint.Contains("?")) { "&" } else { "?" }
        $fullUrl = "$($Credentials.DataEndpoint)$separator" + "timestamp=$formattedTime"
        
        Write-Host "Calling API: $fullUrl"
        
        $response = Invoke-RestMethod -Uri $fullUrl -Method GET -Headers $headers
        
        Write-Host "API call successful for time: $formattedTime"
        Write-Host "Response: $($response | ConvertTo-Json -Compress)"
        
        return $response
    }
    catch {
        Write-Error "Failed to call API endpoint: $_"
        throw
    }
}

# Main execution
try {
    Write-Host "Starting API call at $(Get-Date)"
    
    # Get credentials
    $credentials = Get-ApiCredentials
    
    # Generate token
    $bearerToken = Get-BearerToken -Credentials $credentials
    
    # Call API
    $apiResponse = Invoke-ApiEndpoint -Token $bearerToken -Credentials $credentials
    
    Write-Host "API call completed successfully"
}
catch {
    Write-Error "API call failed: $_"
}
