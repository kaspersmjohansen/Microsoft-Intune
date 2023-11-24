# Configure Powershell execution and PSGallery as trusted repository
Set-ExecutionPolicy -Scope Process Unrestricted -Force
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

# Install NuGet
Install-PackageProvider -Name NuGet -Force

# Import WindowsAutopilot Powershell module
Install-Module AzureAD -Force -Scope CurrentUser
Install-Module WindowsAutopilotIntune -Force -Scope CurrentUser
Install-Module Microsoft.Graph.Intune -Force -Scope CurrentUser 
Install-Module Microsoft.Graph.Authentication -Force -Scope CurrentUser
Install-Module Microsoft.Graph.Identity.DirectoryManagement -Force -Scope CurrentUser
Import-Module AzureAD
Import-Module WindowsAutopilotIntune
Import-Module Microsoft.Graph.Intune
Import-Module Microsoft.Graph.Identity.DirectoryManagement
Import-Module Microsoft.Graph.Authentication

# Remember to have the correct permissions configured on the Graph Powershell or command-line app registration in Entra ID
# Permissions are DeviceManagementConfiguration.Read.All,DeviceManagementManagedDevices.Read.All,DeviceManagementRBAC.Read.All,DeviceManagementServiceConfig.Read.All, Domain.Read.All
# During first time logon you might have to have Global Administrator access to configure permissions on the app registration and use the -Scope with the Connect-MGGraph command
Connect-MGGraph -Tenantid "pawsko.dk" -Scope DeviceManagementConfiguration.Read.All,DeviceManagementManagedDevices.Read.All,DeviceManagementRBAC.Read.All,DeviceManagementServiceConfig.Read.All, Domain.Read.All

# Get Autopilot Configuration Profile

$AutoPilotConfigName = "AutopilotTEST"
$AutoPilotJSONOutputFolder = "C:\Users\KasperSvenMozartJoha\OneDrive - APENTO\Kunder\Paw Sko\AutoPilot Configs"
If (!(Test-Path -Path $($AutoPilotJSONOutputFolder + "\" + $AutoPilotConfigName)))
{
    New-Item -Path $AutoPilotJSONOutputFolder -Name $AutoPilotConfigName -ItemType Directory
}
Get-AutoPilotProfile -id $((Get-AutoPilotProfile | where {$_.DisplayName -eq $AutoPilotConfigName}).id)| ConvertTo-AutoPilotConfigurationJSON | Out-File -FilePath "$AutoPilotJSONOutputFolder\AutopilotConfigurationFile.json" -Encoding ASCII

# Get the ZtdCorrelationID from the Auto pilot JSON file
(device.enrollmentProfileName -eq "OfflineAutopilotprofile-0485ebb4-8bc6-4496-8c58-f36db48bd05e")