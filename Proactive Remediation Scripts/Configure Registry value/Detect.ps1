$RegKey = "HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\Outlook\Setup"
$RegValueName = "DisableRoamingSignaturesTemporaryToggle"
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