#-------------------------------------------------------------------------------- 
# Name: virtualwarlock.net - Kasper Johansen
# Set-OfficeTemplates.ps1, March 2023
# 
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

#Variables
$CompanyName = "virtualwarlock.net"
$Scriptversion = "1.0"
$OfficeTemplatesPath = "$env:APPDATA\Microsoft\Templates"
$OutlookStationaryPath = "$env:APPDATA\Microsoft\Stationery"

# Configure log file and log file path
$LogFile = "Set-OfficeTemplates.log"
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"

If (!(Test-Path -Path $LogPath))
    {
        New-Item -Path $LogPath -ItemType Directory
    }
        
    Start-Transcript -Path "$LogPath\$LogFile" | Out-Null

# Create Templates folder, if not exist
If (!(Test-Path -Path $OfficeTemplatesPath))
{
    New-Item -Path $OfficeTemplatesPath -ItemType Directory -Verbose
}

# Copy Office templates
Get-ChildItem -Path .\Office -Include ("*.dotx","*.xltx","*.potx") -Recurse | Copy-Item -Destination $OfficeTemplatesPath -Force -Verbose

# Create Stationery folder, if not exist
If (!(Test-Path -Path $OutlookStationaryPath))
{
    New-Item -Path $OutlookStationaryPath -ItemType Directory -Verbose
}

# Copy Outlook stationery
Get-ChildItem -Path .\Outlook -Include ("*.thmx") -Recurse | Copy-Item -Destination $OutlookStationaryPath -Force -Verbose

# Create registry key and value to detect if Office Templates are installed/copied
$RegKey = "HKCU:Software\$CompanyName\Intune\OfficeTemplates"
$RegValue = "OfficeTemplates"
$RegData = $Scriptversion      

If (!(Test-Path -Path $RegKey))
{
    New-Item -Path "HKCU:Software\$CompanyName" -Verbose
    New-Item -Path "HKCU:Software\$CompanyName\Intune" -Verbose
    New-Item -Path "HKCU:Software\$CompanyName\Intune\OfficeTemplates" -Verbose

    New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "String" -Verbose
}
else {
    New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "String" -Verbose
}

# Create registry key and value to detect if Outlook Stationery is installed/copied
$RegKey = "HKCU:Software\$CompanyName\Intune\OfficeTemplates"
$RegValue = "OutlookStationery"
$RegData = $Scriptversion      

If (!(Test-Path -Path $RegKey))
{
    New-Item -Path "HKCU:Software\$CompanyName" -Verbose
    New-Item -Path "HKCU:Software\$CompanyName\Intune" -Verbose
    New-Item -Path "HKCU:Software\$CompanyName\Intune\OfficeTemplates" -Verbose

    New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "String" -Verbose
}
else {
    New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "String" -Verbose
}

Stop-Transcript