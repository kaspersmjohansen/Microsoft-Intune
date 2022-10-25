$MgmtGroup = "0168c652-ee23-4281-b0fd-f20850cb9942"

$Groups = "App-Install-Citrix-Provisioning-Console","App-Install-FileZilla-Client","App-Install-FileZilla-Server","App-Install-FSLogix-Apps",
          "App-Install-FSLogix-Apps-Java-Rule-Editor","App-Install-FSLogix-Apps-Rule-Editor","App-Install-Handbrake","App-Install-LAPS-Management",
          "App-Install-ProtonVPN","App-Install-RoyalTS","App-Install-SCVMM","App-Install-SQL-Management-Studio"
ForEach ($Group in $Groups)
{
    $GroupID = (Get-AzureADGroup -Filter "DisplayName eq '$Group'").ObjectID
    Add-AzureADGroupMember -ObjectId $GroupID -RefObjectId $MgmtGroup
}
