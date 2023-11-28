<#
.NAME
    Set-TeamsBackGround.ps1

.SYNOPSIS
    Copy images files to be used as Microsoft Teams backgrounds

.DESCRIPTION
    This script copies the supported image file types (jpg, png, bmp) to the user's profile. 
    To be able to select custom images in Microsoft Teams, image files have to be copied to the $env:APPDATA\Microsoft\Teams\Backgrounds\Uploads folder

    For the script to work, a certain folder structure has to be created.

    File/Folder structure:

    Containing Folder:
    image files (jpg, png, bmp)
    Set-TeamsBackGround.ps1

    As this script copies files to the user's profile, it has to be run in user context.

    Variable documentation:

    $CompanyName should contain the current companyname, or something unique to identify the company
    
    $ScriptVersion should contain a version identifier such as "1.0", "1.1" etc.

    $TeamsUploadFolder is preconfigured to $env:APPDATA\Microsoft\Teams\Backgrounds\Uploads, this should not be changed, as background images will not be available in Teams

    A transcript logfile is created in :\Users\$env:username\$CompanyName which creates a verbose output if this script
    
.NOTES
    Author:             Kasper Johansen
    Website:            https://virtualwarlock.net
    Last modified Date: 31-03-2022
#>

# Relaunch script in 64-bit context
If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
    }
    Catch {
        Throw "Failed to start $PSCOMMANDPATH"
    }
    Exit
}

# Variables
$CompanyName = ""
$Scriptversion = "1.0"
$TeamsUploadFolder = "$env:APPDATA\Microsoft\Teams\Backgrounds\Uploads"

# Configure log file and log file path
$LogFile = "Set-TeamsBackground.log"
$LogPath = "$($env:USERPROFILE)\$CompanyName"

If (!(Test-Path -Path $LogPath))
    {
        New-Item -Path $LogPath -ItemType Directory
    }
        
    Start-Transcript -Path "$LogPath\$LogFile" | Out-Null

# Create Teams upload folder, if not exist
If (!(Test-Path -Path $TeamsUploadFolder))
{
    New-Item -Path $TeamsUploadFolder -ItemType Directory -Verbose
}

# Copy Files to Teams upload folder directory
Get-ChildItem -Path .\ -Include ("*.jpg","*,jpeg","*.png","*.bmp") -Recurse | Copy-Item -Destination $TeamsUploadFolder -Force -Verbose

# Create registry key and value to detect if Teams backgrounds are installed/copied
$RegKey = "HKCU:Software\$CompanyName\Intune\TeamsBackgrounds"
$RegValue = "TeamsBackground"
$RegData = $Scriptversion      

If (!(Test-Path -Path $RegKey))
{
    New-Item -Path "HKCU:Software\$CompanyName" -Verbose
    New-Item -Path "HKCU:Software\$CompanyName\Intune" -Verbose
    New-Item -Path "HKCU:Software\$CompanyName\Intune\TeamsBackgrounds" -Verbose

    New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "String" -Verbose
}
else {
    New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "String" -Verbose
}

Stop-Transcript