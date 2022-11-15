#Requires -Version 5.1
#Requires -RunAsAdministrator

# Configure Microsoft Powershell Gallery (PSGallery) as a trusted source
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -Verbose

function Install-GraphModules {
# Install required Powershell Modules
Install-PackageProvider -Name NuGet -Force
Install-Module -Name Microsoft.Graph.DeviceManagement -Force
Install-Module -Name Microsoft.Graph.DeviceManagement.Actions -Force
Install-Module -Name Microsoft.Graph.DeviceManagement.Administration -Force
Install-Module -Name Microsoft.Graph.DeviceManagement.Enrolment -Force
Install-Module -Name Microsoft.Graph.DeviceManagement.Functions -Force
Install-Module -Name Microsoft.Graph.Authentication -Force

}
$Scopes = "DeviceManagementApps.Read.All","DeviceManagementConfiguration.Read.All",
          "DeviceManagementManagedDevices.Read.All","DeviceManagementRBAC.Read.All",
          "DeviceManagementServiceConfig.Read.All"

$Scopes = "DeviceManagementServiceConfig.Read.All", "DeviceManagementConfiguration.Read.All"
Connect-MgGraph -Scopes $Scopes
Select-MgProfile beta

Find-MgGraphCommand -command Get-MgDeviceManagementDeviceCompliancePolicy | Select -First 1 -ExpandProperty Permissions

# Document Configuration Policies

# Document Compliance Policies

# Document Windows Update for Business

# Document Windows Autopatch

# Document Enrollment Configuration
(Get-MgDeviceManagementDeviceEnrollmentConfiguration -DeviceEnrollmentConfigurationId 70908e37-35ff-45a1-88d5-16bc5cd3b9b8_Windows10EnrollmentCompletionPageConfiguration).AdditionalProperties

# Document Apps

# Document Scripts

# Document Proactive Remediation