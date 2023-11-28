# Configure Powershell execution and PSGallery as trusted repository
Set-ExecutionPolicy -Scope Process Unrestricted -Force
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

# Install NuGet
Install-PackageProvider -Name NuGet -Force

# Import WindowsAutopilot Powershell module
# Install-Module AzureAD -Force -Scope CurrentUser
Install-Module WindowsAutopilotIntune -Force -Scope CurrentUser
# Install-Module Microsoft.Graph.Intune -Force -Scope CurrentUser 
# Install-Module Microsoft.Graph.Authentication -Force -Scope CurrentUser
Install-Module Microsoft.Graph.Identity.DirectoryManagement -Force -Scope CurrentUser
# Import-Module AzureAD
Import-Module WindowsAutopilotIntune
# Import-Module Microsoft.Graph.Intune
Import-Module Microsoft.Graph.Identity.DirectoryManagement
# Import-Module Microsoft.Graph.Authentication

# Remember to have the correct permissions configured on the Graph Powershell or command-line app registration in Entra ID
# Permissions are DeviceManagementConfiguration.Read.All,DeviceManagementManagedDevices.Read.All,DeviceManagementRBAC.Read.All,DeviceManagementServiceConfig.Read.All, Domain.Read.All
# During first time logon you might have to have Global Administrator access to configure permissions on the app registration and use the -Scope with the Connect-MGGraph command
Connect-MGGraph -Tenantid "pawsko.dk" -Scope DeviceManagementConfiguration.Read.All,DeviceManagementManagedDevices.Read.All,DeviceManagementRBAC.Read.All,DeviceManagementServiceConfig.Read.All, Domain.Read.All

# Get Autopilot Configuration Profile
# $AutoPilotConfigName = "AutopilotTEST"
$AutoPilotConfigs = Get-AutoPilotProfile
$AutoPilotJSONOutputFolder = "C:\Temp"

If (!(Test-Path -Path $($AutoPilotJSONOutputFolder + "\" + $AutoPilotConfigName)))
{
    New-Item -Path $AutoPilotJSONOutputFolder -Name $AutoPilotConfigName -ItemType Directory
}
ForEach ($AutopilotConfig in $AutoPilotConfigs)
{
    $AutopilotProfileName = (Get-AutoPilotProfile -Id $AutopilotConfig.Id).DisplayName    
    New-Item -Path $AutoPilotJSONOutputFolder -Name $AutopilotProfileName -ItemType Directory
    Get-AutoPilotProfile -Id $AutopilotConfig.Id| ConvertTo-AutoPilotConfigurationJSON | Out-File -FilePath "$AutoPilotJSONOutputFolder\$AutopilotProfileName\AutopilotConfigurationFile.json" -Encoding ASCII
}

# Create rule syntax with correlation ID from Autopilot profile JSON
# (device.enrollmentProfileName -eq "OfflineAutopilotprofile-0485ebb4-8bc6-4496-8c58-f36db48bd05e")

# Get correlation ID from Autopilot profile JSON
$AutopilotConfigJSONs = Get-ChildItem -Path $AutoPilotJSONOutputFolder -Filter *.json -Recurse
ForEach ($AutopilotConfigJSON in $AutopilotConfigJSONs)
{
    $Config = Get-Content -Path $AutopilotConfigJSON.Fullname -Raw | ConvertFrom-Json
    #$Config.Comment_File
    #$Config.ZtdCorrelationId
    $Comment = $Config.Comment_File
    $CorrelationID = $Config.ZtdCorrelationId
    Write-Host "$Comment"
    Write-host "(device.enrollmentProfileName -eq `"OfflineAutopilotprofile-$CorrelationID`")"
    Write-Host ""
}

ForEach ($AutopilotConfig in $AutoPilotConfigs)
{
    $AutopilotProfileId = $AutopilotConfig.ID
    Get-AutopilotProfileAssignments -id $AutopilotProfileId
    #Get-AutoPilotProfile -id $AutopilotProfileId #| Get-AutopilotProfileAssignments
}

# Create Autopilot group
$DisplayName = "Test Group"
$Description = "Test Group"
$MailNickName = "TestGroup"
$MembershipRule = "(device.enrollmentProfileName -eq `"OfflineAutopilotprofile-0485ebb4-8bc6-4496-8c58-f36db48bd05e`")"
New-MgGroup -DisplayName $DisplayName -Description $Description -MailEnabled:$False -MailNickname $MailNickName -SecurityEnabled:$True -GroupTypes "DynamicMembership" -MembershipRule $MembershipRule -MembershipRuleProcessingState "On"