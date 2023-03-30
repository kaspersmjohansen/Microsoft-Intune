<#
.NAME
    Set-OfficeTemplates.ps1

.SYNOPSIS
    Copy Office (Word, Excel and Powerpoint) templates.

.DESCRIPTION
    To be able to use custom Office templates, the template files have to be copied to the Custom Office Templates folder in the user's Documents folder. 
    This script copies .dotx, .xltx and .potx files to the Custom Office Templates folder. All files have to be places in a folder called Office.

    File/Folder structure:

    Containing Folder:
    \Office
    Set-OfficeTemplates.ps1

    Excel, Powerpoint and Word are then configured to allow Personal templates to be available when creating af new document. 
    This configuration is delivered as registry changes for Excel, Powerpoint and Word in the HKCU:SOFTWARE\Microsoft\Office\16.0\ registry key

    Lastly an Intune detection registry value is configured, to be able to detect if the script has run or not. 
    This also enables versioning of the script using the $ScriptVersion variable

    Variable documentation:

    $CompanyName should contain the current companyname, or something unique to identify the company
    $ScriptVersion should contain a version identifier such as "1.0", "1.1" etc.

    $OfficeTemplatesPath contains the path of Custom Office Templates folder

    A transcript logfile is created in :\Users\$env:username\$CompanyName which creates a verbose output if this script
    
.NOTES
    Author:             Kasper Johansen
    Website:            https://virtualwarlock.net
    Last modified Date: 30-03-2022
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

$OfficeTemplatesPath = "$($env:USERPROFILE)\Documents" + "\Custom Office Templates"

# Configure log file and log file path
$LogFile = "Set-OfficeTemplates.log"
$LogPath = "$($env:USERPROFILE)\$CompanyName"

If (!(Test-Path -Path $LogPath))
    {
        New-Item -Path $LogPath -ItemType Directory
    }
        
    Start-Transcript -Path "$LogPath\$LogFile"

# Create Custom Office Templates folder, if not exist
If (!(Test-Path -Path $OfficeTemplatesPath))
{
    New-Item -Path $OfficeTemplatesPath -ItemType Directory -Verbose
}

# Copy Office templates to Custom Office Templates folder
Get-ChildItem -Path .\Office -Include ("*.dotx","*.xltx","*.potx") -Recurse | Copy-Item -Destination $OfficeTemplatesPath -Force -Verbose

# Create Excel, Powerpoint and Word Personal Templates Path registry value
$OfficeApps = "Excel","Powerpoint","Word"
ForEach ($App in $OfficeApps)
{
    $OfficeCurrentUserRegPath = "HKCU:SOFTWARE\Microsoft\Office\16.0"

        If (!(Test-Path -Path "$OfficeCurrentUserRegPath\$App\Options"))
        {
            If (!(Test-Path -Path "HKCU:SOFTWARE\Microsoft\Office"))
            {
                New-Item -Path "HKCU:SOFTWARE\Microsoft" -Name "Office" -Verbose
            }
                If (!(Test-Path -Path "HKCU:SOFTWARE\Microsoft\Office\16.0"))
                {
                    New-Item -Path "HKCU:SOFTWARE\Microsoft\Office" -Name "16.0" -Verbose
                }
                    If (!(Test-Path -Path "HKCU:SOFTWARE\Microsoft\Office\16.0\$App"))
                    {
                        New-Item -Path "HKCU:SOFTWARE\Microsoft\Office\16.0" -Name "$App" -Verbose
                    }
                        If (!(Test-Path -Path "HKCU:SOFTWARE\Microsoft\Office\16.0\$App\Options"))
                        {
                            New-Item -Path "HKCU:SOFTWARE\Microsoft\Office\16.0\$App" -Name "Options" -Verbose
                        }
        }
   
    $PersonalTemplatesValue = (Get-ItemProperty "$OfficeCurrentUserRegPath\$App\Options" -ErrorAction SilentlyContinue).PersonalTemplates -eq $null 
    If ($PersonalTemplatesValue -eq $False) {
        Set-ItemProperty -Path "$OfficeCurrentUserRegPath\$App\Options" -Name "PersonalTemplates" -Value $OfficeTemplatesPath -Verbose
    } Else {
        New-ItemProperty -Path "$OfficeCurrentUserRegPath\$App\Options" -Name "PersonalTemplates" -Value $OfficeTemplatesPath -PropertyType ExpandString -Verbose
    }
}

# Create Intune detection registry value
$RegValue = "OfficeTemplates"
$RegKey = "HKCU:Software\$CompanyName\Intune\$RegValue"
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
                    If (!(Test-Path -Path "HKCU:SOFTWARE\$CompanyName\Intune\$RegValue"))
                    {
                        New-Item -Path "HKCU:SOFTWARE\$CompanyName\Intune" -Name "$RegValue" -Verbose
                    }
}                     
$RegValueExist = (Get-ItemProperty "$RegKey" -ErrorAction SilentlyContinue).$RegValue -eq $null 
If ($RegValueExist -eq $False) {
    Set-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -Verbose
} Else {
    New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "String" -Verbose
}

Stop-Transcript