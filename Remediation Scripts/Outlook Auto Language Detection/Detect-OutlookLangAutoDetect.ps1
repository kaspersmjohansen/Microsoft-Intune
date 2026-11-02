<#
.SYNOPSIS
    Detects whether automatic language detection is enabled in classic Outlook.

.DESCRIPTION
    Intune remediation detection script.
    Checks the WordMail langautodetect value used by the classic Outlook (Microsoft 365 Apps) mail editor.
    Corresponds to "Detect language automatically" in the Set Proofing Language dialog.
    Assumes Word is used as the email editor in Outlook (WordMail), which is the default in classic Outlook.
    Must run in user context (Run this script using the logged-on credentials = Yes).

    Exit 0 = compliant, or classic Outlook not installed
    Exit 1 = remediation required

.NOTES
    Author:  Kasper Johansen - kasperjohansen.net
    Version: 1.0
    Date:    2026-11-02
#>

#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'

$OutlookAppPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE'
$RegPath        = Join-Path -Path 'HKCU:\Software\Microsoft\Office\16.0\Word\Options' -ChildPath 'WordMail'
$ValueName      = 'langautodetect'
$ExpectedValue  = 1

try {
    # Skip devices without classic Outlook
    if (-not (Test-Path -Path $OutlookAppPath)) {
        Write-Output 'Compliant: classic Outlook not installed'
        exit 0
    }

    $GetParams = @{
        Path        = $RegPath
        Name        = $ValueName
        ErrorAction = 'SilentlyContinue'
    }
    $CurrentValue = (Get-ItemProperty @GetParams).$ValueName

    if ($CurrentValue -eq $ExpectedValue) {
        Write-Output "Compliant: $($ValueName) = $($CurrentValue)"
        exit 0
    }

    $Display = if ($null -eq $CurrentValue) { 'not set' } else { $CurrentValue }
    Write-Output "Non-compliant: $($ValueName) = $($Display), expected $($ExpectedValue)"
    exit 1
}
catch {
    Write-Output "Detection failed: $($_.Exception.Message)"
    exit 1
}
