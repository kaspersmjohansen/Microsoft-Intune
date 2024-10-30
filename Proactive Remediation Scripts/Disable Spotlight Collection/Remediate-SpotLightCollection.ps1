$RegKey = "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CloudContent"
$RegValueName = "DisableSpotlightCollectionOnDesktop"
$RegValueData = "1"
$RegValueType = "DWORD"

$CheckRegValueData = (Get-ItemProperty -Path Registry::$RegKey -Name $RegValueName -ErrorAction SilentlyContinue).$RegValueName
If ($CheckRegValueData -eq $RegValueData)
{
    Write-Host "$RegKey $RegValueName $RegValueData is configured"
    Exit 0
}
else
{
    [microsoft.win32.registry]::SetValue($RegKey, $RegValueName, $RegValueData, $RegValueType)
    Exit 0
}