# Script to install required AWS PowerShell modules on EC2 instance

Write-Host "Installing AWS PowerShell modules for API Scheduler..."

# Set execution policy if needed
try {
    $currentPolicy = Get-ExecutionPolicy
    if ($currentPolicy -eq "Restricted") {
        Write-Host "Setting execution policy to RemoteSigned..."
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    }
}
catch {
    Write-Warning "Could not set execution policy: $_"
}

# Install AWS Tools for PowerShell
try {
    # Check if modules are already installed
    $secretsModule = Get-Module -ListAvailable -Name "AWS.Tools.SecretsManager"
    $logsModule = Get-Module -ListAvailable -Name "AWS.Tools.CloudWatchLogs"
    
    if (!$secretsModule) {
        Write-Host "Installing AWS.Tools.SecretsManager..."
        Install-Module -Name AWS.Tools.SecretsManager -Force -AllowClobber -Scope CurrentUser
        Write-Host "AWS.Tools.SecretsManager installed successfully"
    } else {
        Write-Host "AWS.Tools.SecretsManager already installed"
    }
    
    if (!$logsModule) {
        Write-Host "Installing AWS.Tools.CloudWatchLogs..."
        Install-Module -Name AWS.Tools.CloudWatchLogs -Force -AllowClobber -Scope CurrentUser
        Write-Host "AWS.Tools.CloudWatchLogs installed successfully"
    } else {
        Write-Host "AWS.Tools.CloudWatchLogs already installed"
    }
    
    # Test module import
    Write-Host "Testing module imports..."
    Import-Module AWS.Tools.SecretsManager
    Import-Module AWS.Tools.CloudWatchLogs
    
    Write-Host "All AWS modules imported successfully"
}
catch {
    Write-Error "Failed to install AWS modules: $_"
    Write-Host "Manual installation steps:"
    Write-Host "1. Run PowerShell as Administrator"
    Write-Host "2. Execute: Install-Module -Name AWS.Tools.SecretsManager -Force"
    Write-Host "3. Execute: Install-Module -Name AWS.Tools.CloudWatchLogs -Force"
}

# Display installed modules
Write-Host "`nInstalled AWS modules:"
Get-Module -ListAvailable -Name "AWS.Tools.*" | Select-Object Name, Version | Format-Table -AutoSize

Write-Host "`nSetup complete! You can now run the API scheduler script."
