$REgKey = "HKLM:SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
$RegName = "Enabled"
$RegValue = "1"

If ((Get-ItemProperty -Path $RegKey -Name $RegName).Value -ne $RegValue)
{
Write-Output "Memory Integrity is disabled"
New-Item -Path "HKLM:SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios" -Name HypervisorEnforcedCodeIntegrity -ItemType DWORD
New-ItemProperty -Path $RegKey -Name $RegName -Value $RegValue -PropertyType DWORD
Exit 0
}
else
{
Write-Output "Memory Integrity is enabled"
Exit 0
}