<#
.NAME
    Set-WallpaperandLockScreen.ps1

.SYNOPSIS
    Copy Windows themes, background images and lock screen images

.DESCRIPTION
    This script configure Windows themes, background images and lock screen images, but does not prevent the user from changing this afterwards.
    This means that the script can be used to conigure an initial personalization of Windows, this personalization is however not enforced which means
    that the user is able to make changes to the personalization settings.

    For the script to work, a certain folder structure has to be created.

    File/Folder structure:

    Containing Folder:
    background.jpg
    lockscreen.jpg
    windows.theme
    Set-WallpaperandLockScreen.ps1

    This script does not support multiple Windows Themes, background images or lock screen images, each file used will have to be specified as a variable.

    The Background image and the lock screen image a copied to a local folder - $env:windir\Customization.
    The Windows Theme is copied to a local folder - $env:windir\Resources\Themes.

    The script supports being applied during the Intune Autopilot process. 
    This will make changes to the Default User, to apply the Windows theme to all and any users logging on. This means that the script will have to run in System context.

    Variable documentation:

    $CompanyName should contain the current companyname, or something unique to identify the company

    $ScriptVersion should contain a version identifier such as "1.0", "1.1" etc.

    $ImageDestinationFolder is preconfigured to $env:windir\Customization, change this if you want another location for the background image and lock screen image

    $ThemeDestinationFolder is preconfigured to $env:windir\Resources\Themes. This location is the default location for Windows themes, it's not advisable to change this location.

    $BackgroundFile is the file name of the background image to be copied

    $LockscreenFile is the file name of the lock screen image to be copied

    $ThemeFile is the file name of the Windows theme file to be copied

    A transcript logfile is created in "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs" which creates a verbose output if this script
    
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
$ImageDestinationFolder = "$env:windir\Customization"
$ThemeDestinationFolder = "$env:windir\Resources\Themes"
$BackgroundFile = "background.jpg"
$LockscreenFile = "lockscreen.jpg"
$ThemeFile = "windows.theme"

$BackgroundImage = "$ImageDestinationFolder\$BackgroundFile"
$LockScreenImage = "$ImageDestinationFolder\$LockscreenFile"

# Configure log file and log file path
$LogFile = "Set-WallPaperandLockScreen.log"
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"

If (!(Test-Path -Path $LogPath))
    {
        New-Item -Path $LogPath -ItemType Directory
    }
        
    Start-Transcript -Path "$LogPath\$LogFile" | Out-Null

# Create background image directory, if not exist
If (!(Test-Path -Path $BackgroundDestinationFolder))
{
    New-Item -Path $BackgroundDestinationFolder -ItemType Directory -Verbose
}

# Create lock screen image directory, if not exist
If (!(Test-Path -Path $LockscreenDestinationFolder))
{
    New-Item -Path $LockscreenDestinationFolder -ItemType Directory -Verbose
}

# Create theme directory, if not exist
If (!(Test-Path -Path $ThemeDestinationFolder))
{
    New-Item -Path $ThemeDestinationFolder -ItemType Directory -Verbose
}

# Copy Files to local directories
Copy-Item -Path .\$BackgroundFile -Destination $BackgroundDestinationFolder -Verbose
Copy-Item -Path .\$LockscreenFile -Destination $LockscreenDestinationFolder -Verbose
Copy-Item -Path .\$ThemeFile -Destination $ThemeDestinationFolder -Verbose

# Configure Windows theme in Default User profile
reg.exe load HKLM\TempUser "C:\Users\Default\NTUSER.DAT" | Out-Host
reg.exe add "HKLM\TempUser\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes" /v InstallTheme /t REG_EXPAND_SZ /d `"$("$env:windir\Resources\Themes\$ThemeFile")`" /f | Out-Host
reg.exe unload HKLM\TempUser | Out-Host

# Create Intune detection registry value
$RegValue = $ThemeFile
$RegKey = "HKLM:Software\$CompanyName\Intune\WindowsTheme"
$RegData = $Scriptversion 

If (!(Test-Path -Path $RegKey))
{
    If (!(Test-Path -Path "HKCU:SOFTWARE\$CompanyName"))
            {
                New-Item -Path "HKCU:SOFTWARE" -Name "$CompanyName" -Verbose
            }
                If (!(Test-Path -Path "HKCU:SOFTWARE\$CompanyName\Intune"))
                {
                    New-Item -Path "HKCU:SOFTWARE\$CompanyName" -Name "Intune" -Verbose
                }
                    If (!(Test-Path -Path "HKCU:SOFTWARE\$CompanyName\Intune\WindowsTheme"))
                    {
                        New-Item -Path "HKCU:SOFTWARE\$CompanyName\Intune" -Name "WindowsTheme" -Verbose
                    }
}                     
$RegValueExist = (Get-ItemProperty "$RegKey" -ErrorAction SilentlyContinue).$RegValue -eq $null 
If ($RegValueExist -eq $False) {
    Set-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -Verbose
} Else {
    New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "String" -Verbose
}

# Create Intune detection registry value
$RegValue = $LockscreenFile
$RegKey = "HKLM:Software\$CompanyName\Intune\WindowsLockScreenImage"
$RegData = $Scriptversion 

If (!(Test-Path -Path $RegKey))
{
    If (!(Test-Path -Path "HKCU:SOFTWARE\$CompanyName"))
            {
                New-Item -Path "HKCU:SOFTWARE" -Name "$CompanyName" -Verbose
            }
                If (!(Test-Path -Path "HKCU:SOFTWARE\$CompanyName\Intune"))
                {
                    New-Item -Path "HKCU:SOFTWARE\$CompanyName" -Name "Intune" -Verbose
                }
                    If (!(Test-Path -Path "HKCU:SOFTWARE\$CompanyName\Intune\WindowsLockScreenImage"))
                    {
                        New-Item -Path "HKCU:SOFTWARE\$CompanyName\Intune" -Name "WindowsLockScreenImage" -Verbose
                    }
}                     
$RegValueExist = (Get-ItemProperty "$RegKey" -ErrorAction SilentlyContinue).$RegValue -eq $null 
If ($RegValueExist -eq $False) {
    Set-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -Verbose
} Else {
    New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "String" -Verbose
}

Stop-Transcript