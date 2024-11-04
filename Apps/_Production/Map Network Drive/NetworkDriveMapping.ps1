<#PSScriptInfo
.SYNOPSIS
    Script to map a network drive
 
.DESCRIPTION
    This script will map a network drive based on the information in the NetworkDriveConfig.json file.
    The script is initially created to map a network drive on cloud only Windows devices, where the UNC share path is a non AD joined Windows server.
    If you have the need to map a network drive using a local user name on a non AD joined Windwso server, this is supported with this script.
    Keep in mind that the username and password is NOT encrypted with this solution, which means you should store the NetworkDriverConfig.json file in a secure location.

.PARAMETER NetworkDrive
    Parameters supported are "Create" and "Remove". Use create to map a network drive. Use remove to unmap/remove a network drive.

.PARAMETER ConfigFile
    Path to the NetworkDriveConfig.json file. Default is the same folder as this script.

.PARAMETER LogDir
    Log file folder. Default is $env:UserProfile\NetworkDriveMapping

.PARAMETER LogFile
    $Logfile name. Default is NetworkDriveMapping-$(Get-Date -Format ddMMyyHHmmss).log
        
.EXAMPLE
    .\NetworkDriveMapping.ps1 -NetworkDrive Create
        Create a new network drive mapping, based on the information provided in the NetworkDriveConfig.json file

    .\NetworkDriveMapping.ps1 -NetworkDrive Remove
        Remove an existing network drive mapping, based on the NetworkDriveLetter parameter provided in the NetworkDriveConfig.json file

.NOTES
None at the moment
        
.VERSION
    0.9.0

.AUTHOR
    Kasper Johansen 
    kmj@apento.com

.COMPANYNAME 
    Apento

.COPYRIGHT
    Feel free to use this as much as you want :)

.RELEASENOTES
    04-11-2024 - 0.9.0 - Script is released as is

.CHANGELOG
    0.9.0 - Initial version
#>

param (
        [Parameter(Mandatory = $true)][ValidateSet("Create","Remove")]
        [string]$NetworkDrive,
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile = ".\NetworkDriveConfig.json",
        [Parameter(Mandatory = $false)]
        [string]$LogDir = "$env:USERPROFILE\NetworkDriveMapping",
        [Parameter(Mandatory = $false)]
        [string]$LogFile = "NetworkDriveMapping-$(Get-Date -Format ddMMyyHHmmss).log"
)

#Region functions
function MapNetworkDrive
{
    Param(
            [Parameter(Mandatory = $true)]
            [string]$LocalPath,
            [Parameter(Mandatory = $true)]
            [string]$RemotePath,
            [Parameter(Mandatory = $true)]
            [string]$Username,
            [Parameter(Mandatory = $true)]
            [string]$Password,
            [Parameter(Mandatory = $true)]
            [string]$Persistent,
            [Parameter(Mandatory = $true)][ValidateSet("Create","Remove")]
            [string]$Status
    )
        If ($Status -eq "Create")
        {
            If ($Persistent -eq "Yes")
            {
                Write-Verbose "Creating persistent network drive - $LocalPath - $RemotePath"
                Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath /delete" -NoNewWindow -Wait -RedirectStandardOutput "$env:USERPROFILE\NetworkDriveMapping\netuse-delete-persistent.log"
                Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath `"$RemotePath`" /user:$Username $Password /Persistent:Yes" -NoNewWindow -Wait -RedirectStandardOutput "$env:USERPROFILE\NetworkDriveMapping\netuse-create-persistent.log"
            }

            If ($Persistent -eq "No")
            {
                Write-Verbose "Creating a non-persistent network drive - $LocalPath - $RemotePath"
                Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath /delete" -NoNewWindow -Wait -RedirectStandardOutput "$env:USERPROFILE\NetworkDriveMapping\netuse-delete-nonpersistent.log"
                Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath `"$RemotePath`" /user:$Username $Password /Persistent:No" -NoNewWindow -Wait -RedirectStandardOutput "$env:USERPROFILE\NetworkDriveMapping\netuse-create-nonpersistent.log"
            }
        }

        If ($Status -eq "Remove")
        {
            Write-Verbose "Removing network drive - $LocalPath"
            Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath /delete" -NoNewWindow -RedirectStandardOutput "$env:USERPROFILE\NetworkDriveMapping\netuse-remove.log"
        }
}
#Endregion

# Create $LogDir folder if it does not exist
If (!(Test-Path "$LogDir"))
{
    New-Item -Path "$LogDir" -ItemType Directory    
}

# Start transcript log
Start-Transcript -Path $($LogDir+"\"+$LogFile)

<#
# If we are running as a 32-bit process on an x64 system, re-launch as a 64-bit process
if ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64")
{
    if (Test-Path "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe")
    {
        & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath"
        Exit $lastexitcode
    }
}
#>

# Get read NetworkDriveConfig.json configuration file
$Config = Get-Content -Path $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
[string]$ConfNetworkDriveLetter = $Config.NetworkDriveInfo.NetworkDriveLetter
[string]$ConfNetworkPath = $Config.NetworkDriveInfo.NetworkPath
[string]$ConfUsername = $Config.NetworkDriveInfo.Username
[string]$ConfPassword = $Config.NetworkDriveInfo.Password
[string]$ConfPersistent = $Config.NetworkDriveInfo.Persistent

MapNetworkDrive -LocalPath $ConfNetworkDriveLetter -RemotePath $ConfNetworkPath -Username $ConfUsername -Password $ConfPassword -Persistent $ConfPersistent -Status $NetworkDrive

#Region create Intune detection file - NetworkDriveMappingTag.tag
If ($NetworkDrive -eq "Create")
{
    $NetDrv = Get-PSDrive -Name $($ConfNetworkDriveLetter -replace ":","") -ErrorAction SilentlyContinue
    If ($NetDrv -and ($NetDrv.DisplayRoot -eq "$ConfNetworkPath"))
    {
        # Create a tag file just so Intune knows this was installed
        Set-Content -Path "$LogDir\NetworkDriveMappingTag.tag" -Value "$ConfNetworkDriveLetter has been mapped"
    }
    else
    {
        Write-Host "Network drive is not mapped"
    }
}

If ($NetworkDrive -eq "Remove") 
{
    If (Test-Path -Path "$LogDir\NetworkDriveMappingTag.tag" -ErrorAction SilentlyContinue)
    {
        Remove-Item -Path "$LogDir\NetworkDriveMappingTag.tag" -Verbose
    }
}
#Endregion

Stop-Transcript