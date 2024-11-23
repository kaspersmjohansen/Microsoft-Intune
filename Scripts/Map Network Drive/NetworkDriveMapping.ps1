<#PSScriptInfo
.SYNOPSIS
    Script to map a network drive
 
.DESCRIPTION
    This script will map a network drive based on the information in the NetworkDriveConfig.json file.
    The script will map a network drive on cloud only Windows devices, where the UNC share path is a non AD joined Windows server or NAS box.
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
None
        
.VERSION
    1.0.0

.AUTHOR
    Kasper Johansen 
    https://kasperjohansen.net

.COPYRIGHT
    Feel free to use this as much as you want :)

.RELEASENOTES
    23-11-2024 - 1.1.0 - Added Write-Log function.This function is now doing the logging
    16-11-2024 - 1.0.1 - Script info updated
    14-11-2024 - 1.0.0 - Code cleanup
    04-11-2024 - 0.9.0 - Script is released as is

.CHANGELOG
    1.1.0 - Added Write-Log function and adapted the code to used this function to log events
    1.0.1 - Changed some wording in the description section of the script
    1.0.0 - Removed a few lines of code used for testing
    0.9.0 - Initial release
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

# Function to write log file
# Credit goes to Sean McAvinue for this write log function - https://seanmcavinue.net/2024/08/07/a-simple-and-effective-powershell-log-function/
Function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Message,
        [Parameter(Mandatory = $true)]
        [String]$LogFilePath,
        [Parameter(Mandatory = $true)]
        [String]$LogType,
        [Parameter(Mandatory = $false)]
        [switch]$DebugEnabled = $false
    )
    $Date = Get-Date
    $Message = "$Date - [$LogType] $Message"
    Add-Content -Path $LogFilePath -Value $Message
    if ($DebugEnabled) {
        If ($LogType -eq "Error") {
            write-host $Message -ForegroundColor Red
        }
        elseif ($LogType -eq "Warning") {
            write-host $Message -ForegroundColor Yellow
        }
        else {
            write-host $Message
        }
    }
}

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
            [Parameter(Mandatory = $true)][ValidateSet("Yes","No")]
            [string]$Persistent,
            [Parameter(Mandatory = $true)][ValidateSet("Create","Remove")]
            [string]$Status
    )
        If ($Status -eq "Create")
        {
            If ($Persistent -eq "Yes")
            {
                Write-Verbose "Creating persistent network drive - $LocalPath - $RemotePath"
                Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath /delete" -NoNewWindow -Wait
                Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath `"$RemotePath`" /user:$Username $Password /Persistent:Yes" -NoNewWindow -Wait
            }

            If ($Persistent -eq "No")
            {
                Write-Verbose "Creating a non-persistent network drive - $LocalPath - $RemotePath"
                Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath /delete" -NoNewWindow -Wait
                Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath `"$RemotePath`" /user:$Username $Password /Persistent:No" -NoNewWindow -Wait
            }
        }

        If ($Status -eq "Remove")
        {
            Write-Verbose "Removing network drive - $LocalPath"
            Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath /delete" -NoNewWindow
        }
}
#Endregion

# Create $LogDir folder if it does not exist
If (!(Test-Path "$LogDir"))
{
    New-Item -Path "$LogDir" -ItemType Directory -ErrorAction Continue
    Write-Log -Message "$LogDir created" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
}

# Read NetworkDriveConfig.json configuration file
$Config = Get-Content -Path $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
[string]$ConfNetworkDriveLetter = $Config.NetworkDriveInfo.NetworkDriveLetter
[string]$ConfNetworkPath = $Config.NetworkDriveInfo.NetworkPath
[string]$ConfUsername = $Config.NetworkDriveInfo.Username
[string]$ConfPassword = $Config.NetworkDriveInfo.Password
[string]$ConfPersistent = $Config.NetworkDriveInfo.Persistent

# Map network drive
If ($NetworkDrive -eq "Create")
{    
    try {
        Write-Log -Message "Mapping network drive" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
        Write-Log -Message "Network drive letter: $ConfNetworkDriveLetter" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
        Write-Log -Message "Network drive path: $ConfNetworkPath" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
        Write-Log -Message "Network drive username: $ConfUsername" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
        Write-Log -Message "Network drive persistent: $ConfPersistent" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
        MapNetworkDrive -LocalPath $ConfNetworkDriveLetter -RemotePath $ConfNetworkPath -Username $ConfUsername -Password $ConfPassword -Persistent $ConfPersistent -Status $NetworkDrive
    }
    catch {
        Write-Log -Message "Failed to map network drive: $ConfNetworkDriveLetter" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile)
        Write-Log -Message "Error: $_" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile) 
        Exit 1
    }

    # Create Intune detection file -NetworkDriveMappingTag.tag
    try {        
        $NetDrv = Get-PSDrive -Name $($ConfNetworkDriveLetter -replace ":","") -ErrorAction Continue
        If ($NetDrv -and ($NetDrv.DisplayRoot -eq "$ConfNetworkPath"))
        {
            Write-Log -Message "Network drive: $ConfNetworkDriveLetter - $ConfNetworkPath mapped successfully" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
            Write-Log -Message "Create tag file: NetworkDriveMappingTag.tag in $Logdir" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
            Set-Content -Path "$LogDir\NetworkDriveMappingTag.tag" -Value "$ConfNetworkDriveLetter has been mapped"
        }
        else
        {
            Write-Log -Message "Network drive path: $ConfNetworkPath not found" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile)
        }
    }
    catch {
        Write-Log -Message "Failed to create tag file: NetworkDriveMappingTag.tag - Error: $_" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile)
        Exit 1
    }
}

If ($NetworkDrive -eq "Remove") 
{
    try {
        Write-Log -Message "Removing network drive: $ConfNetworkDriveLetter" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
        MapNetworkDrive -LocalPath $ConfNetworkDriveLetter -RemotePath $ConfNetworkPath -Username $ConfUsername -Password $ConfPassword -Persistent $ConfPersistent -Status $NetworkDrive    }
    catch {
        Write-Log -Message "Failed to remove network drive: $ConfNetworkDriveLetter" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile)
        Write-Log -Message "Error: $_" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile) 
        Exit 1
    }
    
    If (Test-Path -Path "$LogDir\NetworkDriveMappingTag.tag" -ErrorAction Continue)
    {
        try {
            Write-Log -Message "Removing tag file: NetworkDriveMappingTag.tag in $LogDir" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
            Remove-Item -Path "$LogDir\NetworkDriveMappingTag.tag"
        }
        catch {
            Write-Log -Message "Unable to remove tag file: NetworkDriveMappingTag.tag in $LogDir - Error: $_" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile)
            Exit 1
        }        
    }
    else {
        Write-Log -Message "Tag file does not exist: NetworkDriveMappingTag.tag in  $LogDir - Error: $_" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
    }
}
#Endregion