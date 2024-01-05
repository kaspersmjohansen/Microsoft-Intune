$RegKey = "HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\Outlook\Setup"
$RegValueName = "DisableRoamingSignaturesTemporaryToggle"
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