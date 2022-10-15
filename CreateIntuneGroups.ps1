Connect-MSGraph
$GroupNames = "Remote-Desktop"

ForEach ($Group in $GroupNames)
{
    $Name = "App-Install-$Group"
    New-Groups -displayName "$Name" -mailEnabled $false -mailNickname "$Name" -securityEnabled $true    
}

Get-Groups | where {$_.Displayname -like "App-install*"} | select DisplayName, id, MailNickName | Sort-Object DisplayName