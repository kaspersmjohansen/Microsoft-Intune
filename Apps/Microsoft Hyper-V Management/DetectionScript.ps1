# Get Hyper-V Management Clients status
If (!(Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Hyper-V-Management-Clients').State -eq 'Installed')
{
    Exit 1
}

Write-Host "Found it!"