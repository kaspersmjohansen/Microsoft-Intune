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
                Write-Host "Creating persistent network drive - $LocalPath - $RemotePath"
                Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath /delete" -NoNewWindow -Wait
                Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath $RemotePath /user:$Username $Password /Persistent:Yes" -NoNewWindow -Wait
            }

            If ($Persistent -eq "No")
            {
                Write-Host "Creating a non-persistent network drive - $LocalPath - $RemotePath"
                Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath /delete" -NoNewWindow -Wait
                Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath $RemotePath /user:$Username $Password /Persistent:No" -NoNewWindow -Wait
            }
        }

        If ($Status -eq "Remove")
        {
            Write-Host "Removing network drive - $LocalPath"
            Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/C net use $LocalPath /delete" -NoNewWindow
        }
}

# Create $LogDir folder if it does not exist
If (!(Test-Path "$LogDir"))
{
    New-Item -Path "$LogDir" -ItemType Directory    
}

# Start transcript log
Start-Transcript -Path $($LogDir+"\"+$LogFile)

# If we are running as a 32-bit process on an x64 system, re-launch as a 64-bit process
if ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64")
{
    if (Test-Path "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe")
    {
        & "$($env:WINDIR)\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File "$PSCommandPath"
        Exit $lastexitcode
    }
}


$Config = Get-Content -Path $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
#[string]$ConfNetworkDrive = $Config.NetworkDriveInfo.NetworkDrive
[string]$ConfNetworkDriveLetter = $Config.NetworkDriveInfo.NetworkDriveLetter
[string]$ConfNetworkPath = $Config.NetworkDriveInfo.NetworkPath
[string]$ConfUsername = $Config.NetworkDriveInfo.Username
[string]$ConfPassword = $Config.NetworkDriveInfo.Password
[string]$ConfPersistent = $Config.NetworkDriveInfo.Persistent

MapNetworkDrive -LocalPath $ConfNetworkDriveLetter -RemotePath $ConfNetworkPath -Username $ConfUsername -Password $ConfPassword -Persistent $ConfPersistent -Status $NetworkDrive

$NetDrv = Get-PSDrive -Name $($ConfNetworkDriveLetter -replace ":","") -ErrorAction SilentlyContinue
If ($NetworkDrive -eq "Create")
{
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
    Remove-Item -Path "$LogDir\NetworkDriveMappingTag.tag" -Verbose    
}

Stop-Transcript