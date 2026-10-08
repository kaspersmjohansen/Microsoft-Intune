<#
.SYNOPSIS
Installs PSAppDeployToolkit and shows a reboot prompt to the user.

.DESCRIPTION
Ensures NuGet provider and PSGallery trust are configured, installs and imports the
PSAppDeployToolkit module, then displays a restart prompt using
Show-ADTInstallationRestartPrompt. The last 5 minutes of the countdown are displayed 
to the user, and the restart is forced after. A tag file is used to prevent the script from
prompting again on subsequent runs (reboot loop protection). All actions are logged
to a transcript file in the user profile, which is hidden once writing completes.

.PARAMETER CountdownMinutes
Number of minutes before the restart prompt forces a reboot. This value is converted
to seconds for CountdownSeconds. Default is 30 minutes.

.NOTES

.AUTHOR
Kasper M. Johansen | kasperjohansen.net
#>

#Requires -Version 5.1

[CmdletBinding(SupportsShouldProcess)]
param(
    # Minutes until forced restart, converted to seconds for the prompt
    [Parameter()]
    [int]$CountdownMinutes = 30
)

$ErrorActionPreference = 'Stop'

# Convert minutes to seconds for the countdown
$CountdownSeconds = $CountdownMinutes * 60

# Logging setup
$LogFile = "Scheduled_Reboot_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Start logging
Start-Transcript -Path $(Join-Path "$env:USERPROFILE" "$LogFile") -NoClobber
If (!(Test-Path -Path "$env:USERPROFILE\Scheduled_Reboot_tag.tag"))
{
# Create tag file to prevent reboot loop
Write-Output "Creating tag file to prevent reboot loop"
Set-Content -Path "$env:USERPROFILE\Scheduled_Reboot_tag.tag" -Value "Restartet" -Force
Set-ItemProperty -Path "$env:USERPROFILE\Scheduled_Reboot_tag.tag" -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)

# Install NuGet provider if not already installed
if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) 
{
    Write-Output "NuGet provider not found. Installing NuGet provider..."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop | Out-Null
}

# Set PSGallery repository to Trusted if it is not already set
$psg = Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue
if ($psg -and $psg.InstallationPolicy -ne "Trusted") 
{
    Write-Output "Setting PSGallery repository to Trusted..."
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue
}

# Install PSAppDeployToolkit module if not already installed
Write-Output "Installing PSAppDeployToolkit module..."
Install-Module -Name PSAppDeployToolkit -Scope CurrentUser -Force -AllowClobber

Write-Output "Importing PSAppDeployToolkit module..."
Import-Module -Name PSAppDeployToolkit

# Show a reboot prompt to the user
Write-Output "PSADT installation complete. Setting up reboot prompt..."
Show-ADTInstallationRestartPrompt -Title 'Reboot required' -Subtitle "Your computer will restart in $CountdownMinutes minutes to ensure it meets our IT security requirements. Thank you for your understanding." -CountdownSeconds $CountdownSeconds -CountdownNoHideSeconds 300 -AllowMove -NotTopMost

}
else
{
    Write-Output "Scheduled reboot has already happened. Exiting."
}
Stop-Transcript

# Sleep for 30 seconds to ensure the log file is written before hiding it
Start-Sleep -Seconds 30
Set-ItemProperty -Path $(Join-Path "$env:USERPROFILE" "$LogFile") -Name Attributes -Value ([System.IO.FileAttributes]::Hidden)
# SIG # Begin signature block
# MIIeegYJKoZIhvcNAQcCoIIeazCCHmcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBnEt9EiIBHL8pO
# mOVP3kn/GRT1oxOZDgdSFP0QxPFbfaCCA9YwggPSMIICuqADAgECAgg7LtLmDulW
# 1TANBgkqhkiG9w0BAQ0FADCBizELMAkGA1UEBhMCREsxEzARBgNVBAcTCkNvcGVu
# aGFnZW4xIDAeBgkqhkiG9w0BCQEWEWluZm9Acm9ib3BhY2suY29tMREwDwYDVQQK
# EwhSb2JvcGFjazEyMDAGA1UEAxMpS2FzcGVyIFN2ZW4gTW96YXJ0IEpvaGFuc2Vu
# IChQcml2YXRlIGxhYikwHhcNMjUwMzI3MDcxMTMxWhcNNDUwMzI3MDcxMTMxWjCB
# izELMAkGA1UEBhMCREsxEzARBgNVBAcTCkNvcGVuaGFnZW4xIDAeBgkqhkiG9w0B
# CQEWEWluZm9Acm9ib3BhY2suY29tMREwDwYDVQQKEwhSb2JvcGFjazEyMDAGA1UE
# AxMpS2FzcGVyIFN2ZW4gTW96YXJ0IEpvaGFuc2VuIChQcml2YXRlIGxhYikwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQChmJK3YhB0e9BrQ1QVXlUkhfyX
# JYN4TCwugk6ZvZP0Q7Qoyctax/NGZCQrt8GNKqVR1dMycEvXjfgsY7qPgtjE4yTd
# RabcswZK0GiaOsk0GO5PM8jdOKP/w3+7gc7Ev8kU9pMPM11QgQVE/JAa6T0as/y6
# nbIyeNCqfPseC4Rx0r17mjJkRHkUJOUBY4uuXzxLTiwqolJmJstDt2/dfhTx2wKm
# +iDzyi9+th3HoMteB13QIPc6uhc4mXJkVleDeKouRt2xpIPOZUY0ZakKochP6ghr
# h/J7pJHk/zwcEegogBApFVFfkh+d5nkDLOvefLN2UCLDpvXU7Nw6LE/z2BmFAgMB
# AAGjODA2MA4GA1UdDwEB/wQEAwIHgDAPBgNVHRMBAf8EBTADAgEBMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMA0GCSqGSIb3DQEBDQUAA4IBAQBeSoJ0PYSR1xH+8ws8PP4F
# mhVrfT7k7o4hAANZGR+HYxr+0yKPTkBtHC3G2vIbsVcnBKtNiTb519LQDPTssjmw
# xji9F9l2gG6kS0axaQyRfIDpEdswcrCCo+YIh6Suc8GZsc2nxBzSRpdMzA0bAq8A
# FUd9GyotByr8OHWh5Toxhw/lCwQOtBfPGA5deHMSRNXAOihXeatsz4ufk5LVX/lL
# oDsr2lvdsh+N2JBHn/0ElFp83qaqKbroCKlrpYPwrh+OfP6VQiku5Wzz+2VlGhsV
# Lsrhp//CAenx2ki+GcQcz72CfLCWt0f28swM90KSzXgi7nCpESpuOF8654aktbaz
# MYIZ+jCCGfYCAQEwgZgwgYsxCzAJBgNVBAYTAkRLMRMwEQYDVQQHEwpDb3Blbmhh
# Z2VuMSAwHgYJKoZIhvcNAQkBFhFpbmZvQHJvYm9wYWNrLmNvbTERMA8GA1UEChMI
# Um9ib3BhY2sxMjAwBgNVBAMTKUthc3BlciBTdmVuIE1vemFydCBKb2hhbnNlbiAo
# UHJpdmF0ZSBsYWIpAgg7LtLmDulW1TANBglghkgBZQMEAgEFAKCBuDAZBgkqhkiG
# 9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIB
# FTAvBgkqhkiG9w0BCQQxIgQg7AR5Lc3uWVVb/knulZCEJW4FgmP6xksGi+8NMEpY
# Ps0wTAYKKwYBBAGCNwIBDDE+MDygIoAgAFIAbwBiAG8AcABhAGMAawAgAHAAYQBj
# AGsAYQBnAGWhFoAUaHR0cHM6Ly9yb2JvcGFjay5jb20wDQYJKoZIhvcNAQEBBQAE
# ggEAPEcDXTcFmzLn7APxVzLThG+KFdMxXAsIFuJncwWc5CV2s0hA2rYGzbQj+KJ3
# wYV26I/rhiycYbsXksixLrCpckLd053Cg0u3XSoE7JgnKbg8qpDn4OTQY738KT0K
# dycWnfXrYK0+thmOFz8xFyuDKL+cpLaAXP1t8caIXH3aK4dPU3WiEHPYhq1HG3To
# Xx2qj4WMO6KasaUaTx/sgYVJ1bCW9RSjmqukWHlPh2t8sRw9gatRvADK57g711rL
# zvEagm+03YjX+9HPxjSuOAnaskYtBwv/HjwroQALLXUS+sXuDFOxIgz5iY/WkwVa
# 8DvcEmnmYK7kr8We5orJQWQgIKGCF3cwghdzBgorBgEEAYI3AwMBMYIXYzCCF18G
# CSqGSIb3DQEHAqCCF1AwghdMAgEDMQ8wDQYJYIZIAWUDBAIBBQAweAYLKoZIhvcN
# AQkQAQSgaQRnMGUCAQEGCWCGSAGG/WwHATAxMA0GCWCGSAFlAwQCAQUABCBe2BcL
# nlpdsOR3uiWP5QUniqZ08XQ95uBYjVKQTX1jBwIRAPDeP1d+1n5v2PXV5S1OB3sY
# DzIwMjYxMDA4MTIxNzI0WqCCEzowggbtMIIE1aADAgECAhAIT9wzT35FTtvDD4/5
# khg1MA0GCSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdp
# Q2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3Rh
# bXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwHhcNMjYwODA1MDAwMDAwWhcN
# MzcxMTA0MjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFNIQTI1NiBSU0E0MDk2IFRpbWVzdGFt
# cCBSZXNwb25kZXIgMjAyNiAxMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKC
# AgEAtnum8sn+zUr41JtMZbP9OMYw+HwJDpG5xkIu/lqcfNYmMX81YmsUiHLbh9yk
# peWBGKTLhYBrAN9Tdg/QEzG32XcObmgIblnr0CoQ3WSAeDZ6nH6X6VkFyYkJw3QB
# JREwvm4UhLzSxmwPA7cFKRTEOMsmEEj6qJk/dqLEAL+oQYuOwE2UuiX1Vnul8YRe
# IyWd4kgLn9gq6LNXM0UplkR6jL/QHxmb6fMoGBJYbnaUI7XD6cKDpekK2SVMld4i
# DbzeHDtOaaxldH5IxuNusQ69nd8/ZXEiB5Hbxj3RlK13cX1W4DlFXKdv/CEhM8Cj
# 1vvlmvhNroyPdRGbbpBlgyf8Wdu5N6ByhFwURn0U6ozlPoxN22v+fviUhP+6DR54
# 7OZnpBMWDfei1f5sVGwiiW/KQTWOK97g+4RJpPzPNV4VYMAwO2jM2Aty2QYPVmOQ
# TJm0msuXnJrSbl2gf9JylpkJlWXqk1Q4LJsxz+TELoQCZIljbgvTJgoPU2R12ydv
# 8i1UqL/adelA0y7U9Pmmtbze9Xx3rtajC5SzQd1jgfwAwsa90v9YcSPdmeoyoBBA
# /27cCL237l5DTYYPDLQ4ON3OLTGWnvRb6jDrf/T75gMRfUzSLCBQfBusm9+mSWRl
# C/Df6S/e9Q8i13CuhzOT2Jx+V/nlbXM4QoBwlUAhelwwJT0CAwEAAaOCAZUwggGR
# MAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFBTJY4owLtRK+26U8+bjQH717M3iMB8G
# A1UdIwQYMBaAFO9vU0rp5AZ8esrikFb2L9RJ7MtOMA4GA1UdDwEB/wQEAwIHgDAW
# BgNVHSUBAf8EDDAKBggrBgEFBQcDCDCBlQYIKwYBBQUHAQEEgYgwgYUwJAYIKwYB
# BQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBdBggrBgEFBQcwAoZRaHR0
# cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0
# YW1waW5nUlNBNDA5NlNIQTI1NjIwMjVDQTEuY3J0MF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVT
# dGFtcGluZ1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNybDAgBgNVHSAEGTAXMAgGBmeB
# DAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAI3FOmEenVIK35ms
# CYB+fShAsWvSYvLBItoNdAgQ2jIqrGsVsluXMJU/+mRebBc52s6lbKAvOVPXaizm
# KkMLLflEEKDZQx4CkS2t8aHPjkXha3hYZ010htFa3dhNgmalH5vuWvh3tTCf4frT
# S7gPtGc4Z/xaPhQ2AB1mR8eEe/WbH0RWHvVIl6VwQ3+g5FKNfN2N/DWJkf13w2H+
# 2GfqEfbd35Ww8CvoYBjLNIDTadcPWdgsjsiOaK/7EsKJgLjUNIVgvcaFOLLQ/Glr
# A+0ZHJoFUbOr5SJN8zykPspXIXlpDJY/gqFUZRROeab9GVgmhbdOJcD/63RhxPah
# FUGbckRONqMe6DYAv6/mOG0pWd3cPStsdcS7buj5DyniwRY8yooMH6ptx5vpP/pZ
# zBPBeZD2U4IsthyxB5Jaa8qrOkB5z160TXiM5ADMspZ0TfD9MJoq0tFpFPssKRFh
# WeEDYPvcUuN7U7lvcdHl4ezQ3NT/7Ffs1sR1yh/LRbdZ3B3Vc6q2WmD8mDC0p9kz
# l2o73iVtS946IkEj7FkRsZGww1teYxERROC745xrtjvcw9ZyyUjHZWGRIpJeMNsP
# quCDf0fkyHtB+J4AiNZqCQk23rxh+KbpyMTNVKItJ5l92Svl20U9NbqMBOVYl1h5
# 4NEYLJq1/xHWFKPNK903zJZA9P2DMIIGtDCCBJygAwIBAgIQDcesVwX/IZkuQEMi
# DDpJhjANBgkqhkiG9w0BAQsFADBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQDExhE
# aWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwHhcNMjUwNTA3MDAwMDAwWhcNMzgwMTE0
# MjM1OTU5WjBpMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4x
# QTA/BgNVBAMTOERpZ2lDZXJ0IFRydXN0ZWQgRzQgVGltZVN0YW1waW5nIFJTQTQw
# OTYgU0hBMjU2IDIwMjUgQ0ExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKC
# AgEAtHgx0wqYQXK+PEbAHKx126NGaHS0URedTa2NDZS1mZaDLFTtQ2oRjzUXMmxC
# qvkbsDpz4aH+qbxeLho8I6jY3xL1IusLopuW2qftJYJaDNs1+JH7Z+QdSKWM06qc
# hUP+AbdJgMQB3h2DZ0Mal5kYp77jYMVQXSZH++0trj6Ao+xh/AS7sQRuQL37QXbD
# hAktVJMQbzIBHYJBYgzWIjk8eDrYhXDEpKk7RdoX0M980EpLtlrNyHw0Xm+nt5pn
# YJU3Gmq6bNMI1I7Gb5IBZK4ivbVCiZv7PNBYqHEpNVWC2ZQ8BbfnFRQVESYOszFI
# 2Wv82wnJRfN20VRS3hpLgIR4hjzL0hpoYGk81coWJ+KdPvMvaB0WkE/2qHxJ0ucS
# 638ZxqU14lDnki7CcoKCz6eum5A19WZQHkqUJfdkDjHkccpL6uoG8pbF0LJAQQZx
# st7VvwDDjAmSFTUms+wV/FbWBqi7fTJnjq3hj0XbQcd8hjj/q8d6ylgxCZSKi17y
# Vp2NL+cnT6Toy+rN+nM8M7LnLqCrO2JP3oW//1sfuZDKiDEb1AQ8es9Xr/u6bDTn
# YCTKIsDq1BtmXUqEG1NqzJKS4kOmxkYp2WyODi7vQTCBZtVFJfVZ3j7OgWmnhFr4
# yUozZtqgPrHRVHhGNKlYzyjlroPxul+bgIspzOwbtmsgY1MCAwEAAaOCAV0wggFZ
# MBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFO9vU0rp5AZ8esrikFb2L9RJ
# 7MtOMB8GA1UdIwQYMBaAFOzX44LScV1kTN8uZz/nupiuHA9PMA4GA1UdDwEB/wQE
# AwIBhjATBgNVHSUEDDAKBggrBgEFBQcDCDB3BggrBgEFBQcBAQRrMGkwJAYIKwYB
# BQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBBBggrBgEFBQcwAoY1aHR0
# cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZFJvb3RHNC5j
# cnQwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0VHJ1c3RlZFJvb3RHNC5jcmwwIAYDVR0gBBkwFzAIBgZngQwBBAIwCwYJ
# YIZIAYb9bAcBMA0GCSqGSIb3DQEBCwUAA4ICAQAXzvsWgBz+Bz0RdnEwvb4LyLU0
# pn/N0IfFiBowf0/Dm1wGc/Do7oVMY2mhXZXjDNJQa8j00DNqhCT3t+s8G0iP5kvN
# 2n7Jd2E4/iEIUBO41P5F448rSYJ59Ib61eoalhnd6ywFLerycvZTAz40y8S4F3/a
# +Z1jEMK/DMm/axFSgoR8n6c3nuZB9BfBwAQYK9FHaoq2e26MHvVY9gCDA/JYsq7p
# GdogP8HRtrYfctSLANEBfHU16r3J05qX3kId+ZOczgj5kjatVB+NdADVZKON/gnZ
# ruMvNYY2o1f4MXRJDMdTSlOLh0HCn2cQLwQCqjFbqrXuvTPSegOOzr4EWj7PtspI
# HBldNE2K9i697cvaiIo2p61Ed2p8xMJb82Yosn0z4y25xUbI7GIN/TpVfHIqQ6Ku
# /qjTY6hc3hsXMrS+U0yy+GWqAXam4ToWd2UQ1KYT70kZjE4YtL8Pbzg0c1ugMZyZ
# Zd/BdHLiRu7hAWE6bTEm4XYRkA6Tl4KSFLFk43esaUeqGkH/wyW4N7OigizwJWeu
# kcyIPbAvjSabnf7+Pu0VrFgoiovRDiyx3zEdmcif/sYQsfch28bZeUz2rtY/9TCA
# 6TD8dC3JE3rYkrhLULy7Dc90G6e8BlqmyIjlgp2+VqsS9/wQD7yFylIz0scmbKvF
# oW2jNrbM1pD2T7m3XDCCBY0wggR1oAMCAQICEA6bGI750C3n79tQ4ghAGFowDQYJ
# KoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IElu
# YzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQg
# QXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAwMFoXDTMxMTEwOTIzNTk1
# OVowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UE
# CxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBS
# b290IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAv+aQc2jeu+Rd
# SjwwIjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuEDcQwH/MbpDgW61bGl20d
# q7J58soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNwwrK6dZlqczKU0RBEEC7f
# gvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs06wXGXuxbGrzryc/NrDRA
# X7F6Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e5TXnMcvak17cjo+A2raR
# mECQecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtVgkEy19sEcypukQF8IUzU
# vK4bA3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85tRFYF/ckXEaPZPfBaYh2
# mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+SkjqePdwA5EUlibaaRBkr
# fsCUtNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1YxwLEFgqrFjGESVGnZifvaA
# sPvoZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzlDlJRR3S+Jqy2QXXeeqxf
# jT/JvNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFrb7GrhotPwtZFX50g/KEe
# xcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATowggE2MA8GA1UdEwEB/wQF
# MAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9PMB8GA1UdIwQYMBaA
# FEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIBhjB5BggrBgEFBQcB
# AQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggr
# BgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNz
# dXJlZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2hjRodHRwOi8vY3JsMy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMBEGA1UdIAQK
# MAgwBgYEVR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/Q1xV5zhfoKN0Gz22Ftf3
# v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNKei8ttzjv9P+Aufih9/Jy
# 3iS8UgPITtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHrlnKhSLSZy51PpwYDE3cn
# RNTnf+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4oVaO7KTVPeix3P0c2PR3
# WlxUjG/voVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5AY8WYIsGyWfVVa88nq2x2
# zm8jLfR+cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNNn3O3AamfV6peKOK5lDGC
# A3wwggN4AgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJ
# bmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IFRpbWVTdGFtcGluZyBS
# U0E0MDk2IFNIQTI1NiAyMDI1IENBMQIQCE/cM09+RU7bww+P+ZIYNTANBglghkgB
# ZQMEAgEFAKCB0TAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcN
# AQkFMQ8XDTI2MTAwODEyMTcyNFowKwYLKoZIhvcNAQkQAgwxHDAaMBgwFgQUUdmr
# 2gNJc9hPQmaspIJI5rNpxDkwLwYJKoZIhvcNAQkEMSIEIHfMCuP+iRy+K/KbYs6C
# 3T6Xx2V+EJNaNmQsG77pPWaKMDcGCyqGSIb3DQEJEAIvMSgwJjAkMCIEIC2gnaf0
# Ex+f5y22xebpyWVnVa8EPx6nQswNISDhQev8MA0GCSqGSIb3DQEBAQUABIICAHj+
# grtZ+W/sYmCKT8mq1hW1KZ+/Zg3byXic4Ao+ZlqTrExx/yk/QIQk6ZtDsnAx/dek
# dYwrOQR3lby1hu1+p5Nirj9cKszWyrxtQPo3ECQLawc3Ju/Azj2VbLLc5KNSi6Z5
# N7Onl5uT9rKiEwJvQI2+4CG7XCX5O8ErQFbEQdpmPtGakzlUapRxnJMZtD0eZXDv
# WJ0FUx9PkrEqQMzJPxvHfh1o2/uizZqdv4o6OjbC9YmP3Gr0nOuZZrHI/Tbx1e1/
# nl4liOhfXsaYwsCap+o0buc2q6CEGtc60zs/CC0GT1reKQGGgVmTBUheSzG2BkCI
# jAClQixc0TK9/V7uHaj0tuQg8wcnq4wRTrpOaSuPD8A27la439G8jYTTZ5ft2Rvt
# DG9ppJmbxIpTWYMqq8mJ6BUtgeq/hlCMUNXz077RHSbtmb+ovfcN65eUOp1K7k8s
# eWIrihe5/bkGpEeOxsrvyyAM9d8BYK1LyT9ZFIhaXBshW0shCk9soUS/MeLVdUPf
# fVA/9gNEsR7UV+dLzVk8AMoU6EuMqLiMKa9j9U3CsDU1pdMcrnl4mfmFc76mdh+T
# kGN81LqUrItYSNHPz1Dwvt8Ccax99HZgB+bL8sBkSsVX6u2q7wbTlj3eAbt+CNP4
# sF/6anx0odDc+XCeM2KkyLgE6GV1JpB6o23cfjSk
# SIG # End signature block
