<#PSScriptInfo
.SYNOPSIS
    Script to configure a group tag based on user's location ID in Entra.
 
.DESCRIPTION
    This script will configura a group tag on all registered Windows devices on a user, based on the user's location ID in Entra.

.PARAMETER TenantID
    Tenant ID you want to connect to.

.PARAMETER UserLocation
    The location ID country code as shown in Entra. 

.PARAMETER GroupTag
    The group tag you want to apply to the Windows device(s). If left blank, it will clear the group tag on the Windows device.
        
.EXAMPLE
    .\Configure-AutopilotGroupTag.ps1 -TenantID "tenant.com" -UserLocation "DK" -GroupTag "GroupTag"

.NOTES

        
.VERSION
    0.9.0

.AUTHOR
    Kasper Johansen 
    kmj@apento.com

.COMPANYNAME 
    APENTO

.COPYRIGHT
    Feel free to use this as much as you want :)

.RELEASENOTES
    0.9.0 - Initial release

.CHANGELOG

#>
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    [Parameter(Mandatory = $true)]
    [string]$UserLocation,
    [Parameter(Mandatory = $false)]
    [string]$GroupTag
)

#Region install NuGet package provider and required Powershell modules
$RequiredPackageProvider = "NuGet"
ForEach ($PackageProvider in $RequiredPackageProvider)
{
    If (Get-PackageProvider -Name $PackageProvider -ListAvailable -ErrorAction SilentlyContinue)
    {
        Write-Host "The $PackageProvider provider exists"
    }
        else
        {
            Write-Host "The $PackageProvider provider does not exist"
            Write-Host "Installing the $PackageProvider provider"
            Install-PackageProvider -Name $PackageProvider -Scope CurrentUser -Force        
        }
}

$RequiredModules = "Microsoft.Entra.DirectoryManagement","Microsoft.Entra.Users","WindowsAutopilotIntune"
ForEach ($Module in $RequiredModules)
{
    If (Get-Module -ListAvailable -Name $Module) 
    {
        Write-Host "The $Module module exists"
    } 
        else 
        {
            Write-Host "The $Module module does not exist"
            Write-Host "Installing the $Module module"
            Install-Module -Name $Module -Repository PSGallery -Scope CurrentUser -Force -AllowClobber
            Import-module -Name $Module
        }
}
#endregion

# Connect to MgGraph
Connect-MgGraph -TenantId $TenantId -Scopes "DeviceManagementConfiguration.ReadWrite.All","DeviceManagementManagedDevices.ReadWrite.All","DeviceManagementServiceConfig.ReadWrite.All","User.Read.All"

$Users = Get-EntraUser -Filter "UsageLocation eq '$UserLocation'"
ForEach ($User in $Users)
{
    $UPN = $User.UserPrincipalName
    $UserOwnedDevice = Get-EntraUserOwnedDevice -UserId $UPN -All

        ForEach ($Device in $UserOwnedDevice)
        {
            $EntraDevice = Get-EntraDevice -DeviceId $Device.id | Where {$_.OperatingSystem -eq "Windows" -and $_.Model -notlike "*Cloud PC*" -and $_.TrustType -ne "Workplace"}
            $AutopilotDevice = Get-AutopilotDevice | where {$_.azureAdDeviceId -eq "$($EntraDevice.DeviceID)"}

                ForEach ($AutoDevice in $AutopilotDevice)
                {
                    If ($AutoDevice.groupTag -eq "$GroupTag")
                    {
                        Write-Host "$GroupTag is already configured on Autopilot device with the serial: $($AutoDevice.serialNumber)"
                    }
                    else
                    {
                        Write-Host "Configuring group tag $GroupTag on Autopilot device with the serial: $($AutoDevice.serialNumber)"
                        Set-AutopilotDevice -id $($AutoDevice.id) -groupTag $GroupTag    
                    }
                }  
        }
}

Invoke-AutopilotSync