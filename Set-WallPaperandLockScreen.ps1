#-------------------------------------------------------------------------------- 
# Name: HappyAdmin Customization
# install.ps1, June 2022
# Thanks to: https://www.thelazyadministrator.com
# ------------------------------------------------------------------------------------

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
$CompanyName = "warlockstudy.net"
$Scriptversion = "1.0"
$RegPath = "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
$ImageDestinationFolder = "C:\Windows\Customization"
$BackgroundFile = "background.jpg"
$LockscreenFile = "lockscreen.jpg"
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

# Create image directory, if not exist
If (!(Test-Path -Path $ImageDestinationFolder))
{
    New-Item -Path $ImageDestinationFolder -ItemType Directory -Verbose
}

# Copy Files to local directory
Copy-Item -Path .\$BackgroundFile -Destination $ImageDestinationFolder -Verbose
Copy-Item -Path .\$LockscreenFile -Destination $ImageDestinationFolder -Verbose

# Create Personilization registry key, if not exist
If (!(Test-Path -Path $RegPath))
{
    Write-Verbose "Creating $RegPath"
    New-Item $RegPath -Verbose
}
else {
    Write-Verbose "$RegPath already exist"
}

# Lockscreen Registry Keys
New-ItemProperty -Path $RegPath -Name LockScreenImagePath -Value $LockScreenImage -PropertyType String -Force -Verbose
New-ItemProperty -Path $RegPath -Name LockScreenImageUrl -Value $LockScreenImage -PropertyType String -Force -Verbose
New-ItemProperty -Path $RegPath -Name LockScreenImageStatus -Value 1 -PropertyType DWORD -Force -Verbose

# Background Wallpaper Registry Keys
New-ItemProperty -Path $RegPath -Name DesktopImagePath -Value $Backgroundimage -PropertyType String -Force -Verbose
New-ItemProperty -Path $RegPath -Name DesktopImageUrl -Value $Backgroundimage -PropertyType String -Force -Verbose
New-ItemProperty -Path $RegPath -Name DesktopImageStatus -Value 1 -PropertyType DWORD -Force -Verbose

# Create registry key and value to detect if wallpaper is installed
$RegKey = "HKLM:Software\$CompanyName\Intune\WindowsBackgroundImage"
$RegValue = $BackgroundFile
$RegData = $Scriptversion      

If (!(Test-Path -Path $RegKey))
{
    New-Item -Path "HKLM:Software\$CompanyName" -Verbose
    New-Item -Path "HKLM:Software\$CompanyName\Intune" -Verbose
    New-Item -Path "HKLM:Software\$CompanyName\Intune\WindowsBackgroundImage" -Verbose

    New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "DWORD" -Verbose
}
else {
    New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "DWORD" -Verbose
}

# Create registry key and value to detect if lockscreen is installed
$RegKey = "HKLM:Software\$CompanyName\Intune\WindowsLockScreenImage"
$RegValue = $LockscreenFile
$RegData = $Scriptversion      

If (!(Test-Path -Path $RegKey))
{
    New-Item -Path "HKLM:Software\$CompanyName" -Verbose
    New-Item -Path "HKLM:Software\$CompanyName\Intune" -Verbose
    New-Item -Path "HKLM:Software\$CompanyName\Intune\WindowsLockScreenImage" -Verbose

    New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "DWORD" -Verbose
}
else {
    New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "DWORD" -Verbose
}

Stop-Transcript