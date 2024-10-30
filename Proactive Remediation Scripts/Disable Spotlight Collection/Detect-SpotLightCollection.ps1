$RegKey = "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\CloudContent"
$RegValueName = "DisableSpotlightCollectionOnDesktop"
$RegValueData = "1"
$RegValueType = "DWORD"

If (!(Test-Path Registry::$RegKey))
{
    Write-Output 'RegKey not available'
    Exit 1
}

$CheckRegValueData = (Get-ItemProperty -Path Registry::$RegKey -Name $RegValueName -ErrorAction SilentlyContinue).$RegValueName
If ($CheckRegValueData -eq $RegValueData)
{
    Write-Output "$RegKey $RegValueName $RegValueData is configured"
    Exit 0
}
else
{
    Write-Output "$RegKey $RegValueName $RegValueData is not configured"
    Exit 1
}