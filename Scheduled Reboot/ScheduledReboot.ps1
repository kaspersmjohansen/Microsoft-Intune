<#
.SYNOPSIS
Installs PSAppDeployToolkit and shows a reboot prompt to the user.

.DESCRIPTION
Ensures NuGet provider and PSGallery trust are configured, installs and imports the
PSAppDeployToolkit module, then displays a restart prompt using
Show-ADTInstallationRestartPrompt. The last 5 minutes of the countdown are displayed 
to the user, and the restart is forced after. A tag file is used to prevent the script from
prompting again on subsequent runs (reboot loop protection). All actions are logged
to a transcript file in the user profile, which is hidden once writing completes.

.PARAMETER CountdownMinutes
Number of minutes before the restart prompt forces a reboot. This value is converted
to seconds for CountdownSeconds. Default is 30 minutes.

.NOTES

.AUTHOR
Kasper M. Johansen | kasperjohansen.net
#>

#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param(
    # Minutes until forced restart, converted to seconds for the prompt
    [Parameter()]
    [int]$CountdownMinutes = 30
)

$ErrorActionPreference = 'Stop'

# Convert minutes to seconds for the countdown
$CountdownSeconds = $CountdownMinutes * 60

# Logging setup
$LogFile = "Scheduled_Reboot_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Start logging
Start-Transcript -Path $(Join-Path "$env:USERPROFILE" "$LogFile") -NoClobber
If (!(Test-Path -Path "$env:USERPROFILE\Scheduled_Reboot_tag.tag"))
{
# Create tag file to prevent reboot loop
Write-Output "Creating tag file to prevent reboot loop"
Set-Content -Path "$env:USERPROFILE\Scheduled_Reboot_tag.tag" -Value "Restartet" -Force
Set-ItemProperty -Path "$env:USERPROFILE\Scheduled_Reboot_tag.tag" -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)

# Install NuGet provider if not already installed
if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) 
{
    Write-Output "NuGet provider not found. Installing NuGet provider..."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
}

# Set PSGallery repository to Trusted if it is not already set
$psg = Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue
if ($psg -and $psg.InstallationPolicy -ne "Trusted") 
{
    Write-Output "Setting PSGallery repository to Trusted..."
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue
}

# Install PSAppDeployToolkit module if not already installed
Write-Output "Installing PSAppDeployToolkit module..."
Install-Module -Name PSAppDeployToolkit -Scope CurrentUser -Force -AllowClobber

Write-Output "Importing PSAppDeployToolkit module..."
Import-Module -Name PSAppDeployToolkit

# Show a reboot prompt to the user
Write-Output "PSADT installation complete. Setting up reboot prompt..."
Show-ADTInstallationRestartPrompt -Title 'Reboot required' -Subtitle "Your computer will restart in $CountdownMinutes minutes to ensure it meets our IT security requirements. Thank you for your understanding." -CountdownSeconds $CountdownSeconds -CountdownNoHideSeconds 300 -AllowMove -NotTopMost

}
else
{
    Write-Output "Scheduled reboot has already happened. Exiting."
}
Stop-Transcript

# Sleep for 30 seconds to ensure the log file is written before hiding it
Start-Sleep -Seconds 30
Set-ItemProperty -Path $(Join-Path "$env:USERPROFILE" "$LogFile") -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)