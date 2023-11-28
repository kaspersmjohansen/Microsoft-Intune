$LanguageTag = "da"
If ((Get-WinUserLanguageList).LanguageTag -ne $LanguageTag)
{
Write-Output "$LanguageTag culture is not configured"
Exit 1
}
else
{
Write-Output "$LanguageTag culture is configured"
Exit 0
}
