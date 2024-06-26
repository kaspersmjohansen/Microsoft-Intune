$LanguageID = "da-DK"
$OldList = Get-WinUserLanguageList
$NewUserLanguage = New-WinUserLanguageList -Language $LanguageID
$UserLanguageList = $NewUserLanguage + $($OldList | Where-Object { $_.LanguageTag -ne $LanguageID })
$UserLanguageList | select LanguageTag
Set-WinUserLanguageList -LanguageList $UserLanguageList -Force
# Set-WinDefaultInputMethodOverride -InputTip $InputMethodTips