# Autopilot branding script
# Configures Windows wallpaper and lockscreen during Autopilot
# This script is originally devoloped by Steve Weiner - GetRubix and is available here:
# https://github.com/stevecapacity/IntunePowershell/tree/main/Autopilot%20Helper%20Scripts

# The script is modified and rewritten to only support Windows wallpaper and Windows lockscreen.
# The script has been tested in Windows 11 23H2

# Author: Kasper Johansen, kasperjohansen.net

# Variables
$SetWallpaper = "true"
$SetLockScreen = "true"

$WallpaperFileName = "Wallpaper.png"
$WallpaperPath = "C:\Windows\web\wallpaper\Autopilot"
$WallpaperStyle = "Fill" # Valid parameters Fill, Fit, Stretch, Tile, Center, Span
$WallpaperAllowChange = "true" # true #false

$LockscreenFileName = "Wallpaper.png"
$LockscreenPath = "C:\Windows\web\lockscreen\Autopilot"
$LockScreenAllowchange = "true"

$LogDir = "$env:ProgramData\Microsoft\Autopilot\Branding"
$LogFile = "AutopilotBranding-$(Get-Date -Format ddMMyyHHmmss).log"

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

# Create a tag file just so Intune knows this was installed
If (!(Test-Path "$LogDir"))
{
    New-Item -Path "$LogDir" -Name "Autopilot" -ItemType Directory
}
Set-Content -Path "$LogDir\AutopilotBrandingTag.tag" -Value "Installed"

#Region Wallpaper
If ($SetWallpaper -eq "true")
{

    # Set walpaper style
    $Style = Switch ($WallpaperStyle) {
  
        "Fill" {"10"}
        "Fit" {"6"}
        "Stretch" {"2"}
        "Tile" {"0"}
        "Center" {"0"}
        "Span" {"22"}
      
    }

    # Configure Windows wallpaper
    If (!(Test-Path -Path "$env:windir\Resources\OEM Themes"))
    {
        New-Item -Path "$env:windir\Resources" -Name "OEM Themes" -ItemType Directory -Force -Verbose
    }    
    Copy-Item -Path "$PSScriptRoot\Theme\Autopilot.theme" -Destination "$env:windir\Resources\OEM Themes\Autopilot.theme" -Force -Verbose

        If (!(Test-Path -Path "$WallpaperPath"))
        {
            New-Item -Path "$WallpaperPath" -ItemType Directory -Verbose
        }
            # New-Item -Path "C:\Windows\web\wallpaper" -Name "Autopilot" -ItemType Directory -Force -Verbose
            Copy-Item -Path "$PSScriptRoot\Wallpaper\$WallpaperFileName" -Destination "$WallpaperPath\$WallpaperFileName" -Force -Verbose

                # Load default user's registry hive
                Start-Process -Filepath "$env:windir\System32\reg.exe" -Argumentlist "load HKLM\TempUser `"C:\Users\Default\NTUSER.DAT`"" -NoNewWindow -Wait

                # Add Autopilot.theme information to the default user's registry
                Start-Process -Filepath "$env:windir\System32\reg.exe" -Argumentlist "add `"HKLM\TempUser\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes`" /v InstallTheme /t REG_EXPAND_SZ /d `"%SystemRoot%\resources\OEM Themes\Autopilot.theme`" /f" -NoNewWindow -Wait

                # Add wallpaper style information to the default user's registry
                If($WallpaperStyle -eq "Tile") 
                {
                    Start-Process -Filepath "$env:windir\System32\reg.exe" -Argumentlist "add `"HKLM\TempUser\Control Panel\Desktop`" /v WallpaperStyle /t REG_SZ /d `"$Style`" /f" -NoNewWindow -Wait
                    Start-Process -Filepath "$env:windir\System32\reg.exe" -Argumentlist "add `"HKLM\TempUser\Control Panel\Desktop`" /v TileWallpaper /t REG_SZ /d `"1`" /f" -NoNewWindow -Wait
                }
                else
                {
                    Start-Process -Filepath "$env:windir\System32\reg.exe" -Argumentlist "add `"HKLM\TempUser\Control Panel\Desktop`" /v WallpaperStyle /t REG_SZ /d `"$Style`" /f" -NoNewWindow -Wait
                    Start-Process -Filepath "$env:windir\System32\reg.exe" -Argumentlist "add `"HKLM\TempUser\Control Panel\Desktop`" /v TileWallpaper /t REG_SZ /d `"0`" /f" -NoNewWindow -Wait
                }
                
                # Garbage collection. This is needed to avoid corrupting the default user's profile
                [gc]::Collect()

                # Unload default user's registry hive
                Start-Process -Filepath "$env:windir\System32\reg.exe" -Argumentlist "unload HKLM\TempUser" -NoNewWindow -Verbose
}
#Endregion Wallpaper

#Region Lockscreen

If ($SetLockScreen -eq "true")
{
    $RegKey = "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"

# Create lock screen image folder
If (!(Test-Path -Path "$LockscreenPath"))
{
    New-Item -Path "$LockscreenPath" -ItemType Directory -Verbose
}

# Copy lock screen image to lock screen image folder
Copy-Item -Path "$PSScriptRoot\Lockscreen\$LockscreenFileName" -Destination "$LockscreenPath\$LockscreenFileName" -Force -Verbose

# Enforce lock screen image
If (!(Test-Path -Path $RegKey))
{
    New-Item -Path $RegKey -Force -Verbose
}
New-ItemProperty -Path $RegKey -Name "LockScreenImageStatus" -Value "0" -PropertyType "Dword" -Force
New-ItemProperty -Path $RegKey -Name "LockScreenImagePath" -Value "$LockscreenPath\$LockscreenFileName" -PropertyType "String" -Force
New-ItemProperty -Path $RegKey -Name "LockScreenImageUrl" -Value "$LockscreenPath\$LockscreenFileName" -PropertyType "String" -Force

If ($LockScreenMandatory -eq "true")
{
    New-ItemProperty -Path $RegKey -Name "LockScreenImageStatus" -Value "0" -PropertyType "Dword" -Force
}
}
#Endregion

Stop-Transcript