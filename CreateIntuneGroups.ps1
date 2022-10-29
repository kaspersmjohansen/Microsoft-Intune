function New-IntuneGroup
{
    param(
        [Parameter(Mandatory=$true)]
         $Name,
         [string]$Prefix,
         [string]$Affix
    )
        Import-Module -Name Microsoft.Graph.Intune
        Connect-MSGraph
        
        ForEach ($Group in $Name)
        {
            If ($Prefix -and [string]::IsNullOrEmpty($Affix))
            {
                $GroupName = $Prefix + $Group
                New-Groups -displayName "$GroupName" -mailEnabled $false -mailNickname "$GroupName" -securityEnabled $true    
            }            
                If ($Affix -and [string]::IsNullOrEmpty($Prefix))
                {
                    $GroupName = $Group + $Affix
                    New-Groups -displayName "$GroupName" -mailEnabled $false -mailNickname "$GroupName" -securityEnabled $true     
                }
                    If ($Prefix -and $Affix)
                    {
                        $GroupName = $Prefix + $Group + $Affix
                        New-Groups -displayName "$GroupName" -mailEnabled $false -mailNickname "$GroupName" -securityEnabled $true     
                    }                    
                        If ([string]::IsNullOrEmpty($Prefix) -and [string]::IsNullOrEmpty($Affix))
                        {
                            New-Groups -displayName "$Group" -mailEnabled $false -mailNickname "$Group" -securityEnabled $true
                        }
        }

}

$GroupName = "Git-for-Windows"
$GroupPrefix = "App-Install-"
$GroupAffix = ""


New-IntuneGroup -Name $GroupName -Prefix $GroupPrefix

New-IntuneGroup -Name $GroupName -Affix $GroupAffix

New-IntuneGroup -Name $GroupName -Prefix $GroupPrefix -Affix $GroupAffix

Get-Groups | where {$_.Displayname -like "*Test*"} | select DisplayName, id, MailNickName | Sort-Object DisplayName