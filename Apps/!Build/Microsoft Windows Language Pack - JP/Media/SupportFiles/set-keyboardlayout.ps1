# Script for Scheduled task
$LanguageID = "ja-JP"
$OldList = Get-WinUserLanguageList
$NewUserLanguage = New-WinUserLanguageList -Language $LanguageID
$InputMethodTips = $NewUserLanguage.InputMethodTips
$UserLanguageList= $($OldList | where { $_.LanguageTag -ne $LanguageID }) + $NewUserLanguage
$UserLanguageList | select LanguageTag
Set-WinUserLanguageList -LanguageList $UserLanguageList -Force
Set-WinDefaultInputMethodOverride -InputTip $InputMethodTips