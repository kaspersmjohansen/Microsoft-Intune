$RegKey = "HKLM:SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
$RegName = "Enabled"
$RegValue = "1"

If ((Get-ItemProperty -Path $RegKey -Name $RegName).Value -ne $RegValue)
{
Write-Output "Memory Integrity is disabled"
Exit 1
}
else
{
Write-Output "Memory Integrity is enabled"
Exit 0
}