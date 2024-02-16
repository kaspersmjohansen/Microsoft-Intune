#Requires -Version 7.0
param(
    [Parameter(Mandatory = $true)]
    $Id,
    [Parameter(Mandatory = $false)][ValidateSet('Any','User','System','UserOrUnknown','SystemOrUnknown')]
    $Scope = "SystemOrUnknown",
    $LogDir = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
)

Set-PackageSource -Name PSGallery -Trusted
#Install-PackageProvider -Name NuGet -Force
Install-Module -Name Microsoft.WinGet.Client
$DateTime = Get-Date -format "ddMMyyyyHHmm"

Install-WinGetPackage -Id $Id -Scope $Scope -Mode Silent -Log $($Logdir + "\" + $Id + "-" + $DateTime)