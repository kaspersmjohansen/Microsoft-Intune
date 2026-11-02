<#
.SYNOPSIS
    Enables automatic language detection in classic Outlook.

.DESCRIPTION
    Intune remediation script.
    Sets the WordMail langautodetect value used by the classic Outlook (Microsoft 365 Apps) mail editor to 1.
    Corresponds to "Detect language automatically" in the Set Proofing Language dialog.
    Assumes Word is used as the email editor in Outlook (WordMail), which is the default in classic Outlook.
    Must run in user context (Run this script using the logged-on credentials = Yes).
    Outlook picks up the change at next start.

    Exit 0 = setting applied and verified
    Exit 1 = remediation failed

.NOTES
    Author:  Kasper Johansen | Apento
    Contact: kmj@apento.com
    Version: 1.0
    Date:    2026-11-02
#>

#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'

$RegPath       = Join-Path -Path 'HKCU:\Software\Microsoft\Office\16.0\Word\Options' -ChildPath 'WordMail'
$ValueName     = 'langautodetect'
$ExpectedValue = 1

try {
    if (-not (Test-Path -Path $RegPath)) {
        if ($PSCmdlet.ShouldProcess($RegPath, 'Create registry key')) {
            New-Item -Path $RegPath -Force | Out-Null
        }
    }

    if ($PSCmdlet.ShouldProcess("$($RegPath)\$($ValueName)", "Set DWORD to $($ExpectedValue)")) {
        $SetParams = @{
            Path         = $RegPath
            Name         = $ValueName
            Value        = $ExpectedValue
            PropertyType = 'DWord'
            Force        = $true
        }
        New-ItemProperty @SetParams | Out-Null

        $Verify = (Get-ItemProperty -Path $RegPath -Name $ValueName).$ValueName
        if ($Verify -ne $ExpectedValue) {
            Write-Output "Remediation failed: $($ValueName) = $($Verify) after write"
            exit 1
        }
    }

    Write-Output "Remediated: $($ValueName) = $($ExpectedValue). Takes effect at next Outlook start."
    exit 0
}
catch {
    Write-Output "Remediation failed: $($_.Exception.Message)"
    exit 1
}
