$RegKey = "HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\Outlook\Setup"
$RegValueName = "DisableRoamingSignaturesTemporaryToggle"
$RegValueData = "1"
$RegValueType = "DWORD" # https://learn.microsoft.com/en-us/dotnet/api/microsoft.win32.registryvaluekind?view=net-8.0&redirectedfrom=MSDN#fields

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