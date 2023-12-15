# Get Hyper-V and Management Tools status
If (!(Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Hyper-V-All').State -eq 'Installed')
{
    Exit 1
}

Write-Host "Found it!"