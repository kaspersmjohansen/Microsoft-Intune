$LanguageTag = "da"
$Language = "da-DK"
If ((Get-WinUserLanguageList).LanguageTag -ne $LanguageTag)
{
Write-Output "$LanguageTag culture is not configured"
Set-WinUserLanguageList -LanguageList $Language -Force
Exit 0
}
else
{
Write-Output "$LanguageTag culture is configured"
Exit 0
}