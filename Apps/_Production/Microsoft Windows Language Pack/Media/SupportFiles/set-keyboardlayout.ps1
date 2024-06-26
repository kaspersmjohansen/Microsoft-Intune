# Script for Scheduled task
$LanguageID = "da-DK"
$OldList = Get-WinUserLanguageList
$NewUserLanguage = New-WinUserLanguageList -Language $LanguageID
$InputMethodTips = $NewUserLanguage.InputMethodTips
$UserLanguageList = $($OldList | Where-Object { $_.LanguageTag -ne $LanguageID }) + $NewUserLanguage
$UserLanguageList | select LanguageTag
Set-WinUserLanguageList -LanguageList $UserLanguageList -Force
Set-WinDefaultInputMethodOverride -InputTip $InputMethodTips