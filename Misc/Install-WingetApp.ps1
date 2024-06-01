#Requires -Version 7.0
Param (
    [Parameter(Mandatory = $true)]
    [string]$PackageId,
    [Parameter(Mandatory = $false)][ValidateSet('Any','User','System','UserOrUnknown','SystemOrUnknown')]
    [string]$InstallScope = "SystemOrUnknown",
    [Parameter(Mandatory = $false)][ValidateSet('winget','msstore')]
    [string]$SourceRepo = "winget",
    [Parameter(Mandatory = $false)]
    [string]$CustomParameters,
    [Parameter(Mandatory = $false)]
    [string]$LogDir = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
)

# Get date and time
$DateTime = Get-Date -format "ddMMyyyyHHmm"

# Create logdir, if not exist
If (!(Test-Path -Path $LogDir))
{
    New-Item -Path $LogDir -ItemType Directory
}

# Start transscript
Start-Transcript -Path $($Logdir + "\" + $PackageId + "-" + $DateTime + "-" + "transcript" + ".log")

Set-PackageSource -Name PSGallery -Trusted | Out-Null
#Install-PackageProvider -Name NuGet -Force
Install-Module -Name Microsoft.WinGet.Client -Force -Verbose
# Import-Module -Name Microsoft.WinGet.Client -Verbose

Import-Module "C:\windows\system32\config\systemprofile\Documents\PowerShell\Modules\Microsoft.WinGet.Client\*\Microsoft.WinGet.Client.psd1"

# Verify the Windows Package Manager is working
Repair-WinGetPackageManager -AllUsers -Latest -Verbose

If (![string]::IsNullOrEmpty($CustomParameters))
{
    $Install = Install-WinGetPackage -Id $PackageId -Scope $InstallScope -Mode Silent -Override $CustomParameters -Log $($Logdir + "\" + $PackageId + "-" + $DateTime + ".log") -Verbose
}
else {
    $Install = Install-WinGetPackage -Id $PackageId -Scope $InstallScope -Mode Silent -Log $($Logdir + "\" + $PackageId + "-" + $DateTime + ".log") -Verbose
}

If ($Install.Status -eq "OK")
{
    Write-Host "$PackageID installed successfully" -Verbose
}
else {
    Write-Host "$PackageID installed failed - Check the logs for more information" -Verbose
}

Stop-Transcript