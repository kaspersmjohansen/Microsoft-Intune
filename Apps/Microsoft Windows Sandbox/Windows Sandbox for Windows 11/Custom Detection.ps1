# Get Windows Sandbox status
If (!(Get-WindowsOptionalFeature -Online -FeatureName 'Containers-DisposableClientVM').State -eq 'Installed')
{
    Exit 1
}

Write-Host "Found it!"