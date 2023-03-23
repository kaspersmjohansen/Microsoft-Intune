#-------------------------------------------------------------------------------- 
# Name: virtualwarlock.net - Kasper Johansen
# Set-TeamsBackground.ps1, March 2023
# Thanks to: https://janbakker.tech/manage-teams-custom-backgrounds-using-intune/
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
$CompanyName = ""
$Scriptversion = "1.0"
$TeamsUploadFolder = "$env:APPDATA\Microsoft\Teams\Backgrounds\Uploads"

# Configure log file and log file path
$LogFile = "Set-TeamsBackground.log"
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"

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
Get-ChildItem -Path .\* -Include *.jpg,*,jpeg,*.png,*bmp | Copy-Item -Destination $TeamsUploadFolder -Force -Verbose

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