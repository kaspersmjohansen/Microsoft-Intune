$RegKey = "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
$RegName = "Value"
$RegValue = "Allow"

If ((Get-ItemProperty -Path $RegKey -Name $RegName).Value -ne $RegValue)
{
Write-Output "Location service is disabled"
Set-ItemProperty -Path $RegKey -Name $RegName -Value $RegValue
Exit 0
}
else
{
Write-Output "Location service is enabled"
Exit 0
}