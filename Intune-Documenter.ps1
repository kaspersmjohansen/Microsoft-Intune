#Requires -Version 5.1
#Requires -RunAsAdministrator

# Configure Microsoft Powershell Gallery (PSGallery) as a trusted source
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -Verbose

function Install-GraphModules {
# Install required Powershell Modules
Install-PackageProvider -Name NuGet -Force
Install-Module -Name Microsoft.Graph.Authentication -Force
Install-Module -Name Microsoft.Graph.DeviceManagement -Force
Install-Module -Name Microsoft.Graph.DeviceManagement.Actions -Force
Install-Module -Name Microsoft.Graph.DeviceManagement.Administration -Force
Install-Module -Name Microsoft.Graph.DeviceManagement.Enrolment -Force
Install-Module -Name Microsoft.Graph.DeviceManagement.Functions -Force
Install-Module -Name Microsoft.Graph.WindowsUpdates -Force

}
$Scopes = "DeviceManagementApps.Read.All","DeviceManagementConfiguration.Read.All",
          "DeviceManagementManagedDevices.Read.All","DeviceManagementRBAC.Read.All",
          "DeviceManagementServiceConfig.Read.All"

$Scopes = "DeviceManagementServiceConfig.Read.All","DeviceManagementConfiguration.Read.All"
Connect-MgGraph -Scopes $Scopes
Select-MgProfile beta

Find-MgGraphCommand -command Get-MgApplication | Select -First 1 -ExpandProperty Permissions

# Document Configuration Policies
ForEach ($policy in Get-MgDeviceManagementDeviceConfiguration)
{
    $Policy.DisplayName
    #$Policy.AdditionalProperties
}

# Document Compliance Policies
ForEach ($policy in Get-MgDeviceManagementDeviceCompliancePolicy)
{
    $Policy.DisplayName
    #$Policy.AdditionalProperties
}

# Document Windows Update for Business
ForEach ($policy in Get-MgDeviceManagementWindowFeatureUpdateProfile)
{
    $Policy.DisplayName
    #$Policy.AdditionalProperties
}

# Document Windows Autopatch

# Document Enrollment Configuration
ForEach ($policy in Get-MgDeviceManagementDeviceEnrollmentConfiguration)
{
    $Policy.DisplayName
    #$Policy.AdditionalProperties
}

# Document Apps

# Document Scripts
ForEach ($policy in Get-MgDeviceManagementDeviceShellScript)
{
    $Policy.DisplayName
    #$Policy.AdditionalProperties
}
# Document Proactive Remediation