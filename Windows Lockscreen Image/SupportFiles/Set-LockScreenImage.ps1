<#
.SYNOPSIS
    Rotates the Windows lock screen image from a pool of images.
.DESCRIPTION
    Selects a random image from a source folder and applies it as the system
    lock screen via the PersonalizationCSP registry keys. The image currently
    configured in the registry is excluded from the selection pool so the
    same image is never applied twice in a row.
.PARAMETER SourceFolder
    Folder containing the candidate images.
.PARAMETER LogFile
    Full path to the log file. Defaults to
    'C:\ProgramData\LockScreenRotator\rotator.log'.
.NOTES
    Author : Kasper Sven Mozart Johansen
    Run as : SYSTEM (required to write PersonalizationCSP)
#>

[CmdletBinding()]
param(
    [string]$SourceFolder = 'C:\ProgramData\LockScreenRotator\Images',
    [string]$LogFile      = 'C:\ProgramData\LockScreenRotator\rotator.log'
)

$ErrorActionPreference = 'Stop'

# Supported image extensions
$ImageExtensions = @(
    '*.jpg','*.jpeg','*.bmp','*.dib','*.png',
    '*.gif','*.jfif','*.jpe','*.tif','*.tiff'
)

function Write-Log {
    param([string]$Message,[string]$Level='INFO')
    $line = "{0} [{1}] {2}" -f (Get-Date -Format 's'), $Level, $Message
    Add-Content -Path $LogFile -Value $line
}

try {
    # Ensure the log directory exists
    $logDir = Split-Path -Path $LogFile -Parent
    if ($logDir -and -not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path $SourceFolder)) {
        throw "Source folder '$SourceFolder' not found."
    }

    $images = Get-ChildItem -Path $SourceFolder -File -Include $ImageExtensions -Recurse |
              Sort-Object FullName
    if ($images.Count -eq 0) { throw "No images found in '$SourceFolder'." }

    # Read the currently configured lock screen path (if any)
    $key     = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
    $current = $null
    if (Test-Path $key) {
        $current = (Get-ItemProperty -Path $key -Name 'LockScreenImagePath' -ErrorAction SilentlyContinue).LockScreenImagePath
    }

    # Exclude the currently configured image from the candidate pool
    $candidates = if ($current) {
        $images | Where-Object { $_.FullName -ne $current }
    } else {
        $images
    }

    # Fallback: if exclusion empties the pool (only one image available), reuse the full list
    if ($candidates.Count -eq 0) {
        Write-Log "Only one image available; reusing the currently configured image." 'WARN'
        $candidates = $images
    }

    # Pick a random image from the filtered pool
    $picked = Get-Random -InputObject $candidates
    $target = $picked.FullName

    # Apply via PersonalizationCSP
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    New-ItemProperty -Path $key -Name 'LockScreenImagePath'   -Value $target -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $key -Name 'LockScreenImageUrl'    -Value $target -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $key -Name 'LockScreenImageStatus' -Value 1       -PropertyType DWord  -Force | Out-Null

    Write-Log "Lock screen set to '$target' (previous: '$current')."
}
catch {
    Write-Log $_.Exception.Message 'ERROR'
    throw
}
# SIG # Begin signature block
# MIIeegYJKoZIhvcNAQcCoIIeazCCHmcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD4qvEjJUyuMbLu
# mG2eQOWGJe+gliCiU5/cISp+yqI/z6CCA9YwggPSMIICuqADAgECAgg7LtLmDulW
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
# FTAvBgkqhkiG9w0BCQQxIgQgs5MTtavwS81m4eyFn6opJoiBQcx4+zPHphBX7aY9
# nA8wTAYKKwYBBAGCNwIBDDE+MDygIoAgAFIAbwBiAG8AcABhAGMAawAgAHAAYQBj
# AGsAYQBnAGWhFoAUaHR0cHM6Ly9yb2JvcGFjay5jb20wDQYJKoZIhvcNAQEBBQAE
# ggEAJu1cxXJbLQao+OhybHWwL09i3sGqsw0XhzbGpi0hg1PAIcMtlOvaAo+QZopd
# j47LTFx/oJprtjyTgvSjSs22Sx0FTKeDmH5h5SX84U+IDm2nLRTD/mK+imPJy9j/
# C+2sBPYDUmeZy5dX8Qas18WC1NSVP5l+wGmE6MG6Q87t7yTJ2IRfNcjxyIObkMc4
# iO9WhUbh7PCCyy59m42d5Vn4YxkFElJmk6AbuoczgzuXAsHZlTYxAxYnXF/wN5sv
# QChSfgAp6Tk6Jf37VpwwNRfgp1SK880oklS+6EeOh7IFzxj0nNMCixVMD6yB8he6
# 3nehOEeG6gxNqB51ss0N3VJcl6GCF3cwghdzBgorBgEEAYI3AwMBMYIXYzCCF18G
# CSqGSIb3DQEHAqCCF1AwghdMAgEDMQ8wDQYJYIZIAWUDBAIBBQAweAYLKoZIhvcN
# AQkQAQSgaQRnMGUCAQEGCWCGSAGG/WwHATAxMA0GCWCGSAFlAwQCAQUABCCCkNAk
# 3TFu0ikciQB9cWZNP1wWtjKOF4B9YZrPVhR5YwIRAJ2OfcHmhInt2VksrTmiyNAY
# DzIwMjYwNzA0MDc0MTU0WqCCEzowggbtMIIE1aADAgECAhAKgO8YS43xBYLRxHan
# lXRoMA0GCSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdp
# Q2VydCwgSW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBUaW1lU3Rh
# bXBpbmcgUlNBNDA5NiBTSEEyNTYgMjAyNSBDQTEwHhcNMjUwNjA0MDAwMDAwWhcN
# MzYwOTAzMjM1OTU5WjBjMQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQs
# IEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFNIQTI1NiBSU0E0MDk2IFRpbWVzdGFt
# cCBSZXNwb25kZXIgMjAyNSAxMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKC
# AgEA0EasLRLGntDqrmBWsytXum9R/4ZwCgHfyjfMGUIwYzKomd8U1nH7C8Dr0cVM
# F3BsfAFI54um8+dnxk36+jx0Tb+k+87H9WPxNyFPJIDZHhAqlUPt281mHrBbZHqR
# K71Em3/hCGC5KyyneqiZ7syvFXJ9A72wzHpkBaMUNg7MOLxI6E9RaUueHTQKWXym
# OtRwJXcrcTTPPT2V1D/+cFllESviH8YjoPFvZSjKs3SKO1QNUdFd2adw44wDcKgH
# +JRJE5Qg0NP3yiSyi5MxgU6cehGHr7zou1znOM8odbkqoK+lJ25LCHBSai25CFyD
# 23DZgPfDrJJJK77epTwMP6eKA0kWa3osAe8fcpK40uhktzUd/Yk0xUvhDU6lvJuk
# x7jphx40DQt82yepyekl4i0r8OEps/FNO4ahfvAk12hE5FVs9HVVWcO5J4dVmVzi
# x4A77p3awLbr89A90/nWGjXMGn7FQhmSlIUDy9Z2hSgctaepZTd0ILIUbWuhKuAe
# NIeWrzHKYueMJtItnj2Q+aTyLLKLM0MheP/9w6CtjuuVHJOVoIJ/DtpJRE7Ce7vM
# RHoRon4CWIvuiNN1Lk9Y+xZ66lazs2kKFSTnnkrT3pXWETTJkhd76CIDBbTRofOs
# NyEhzZtCGmnQigpFHti58CSmvEyJcAlDVcKacJ+A9/z7eacCAwEAAaOCAZUwggGR
# MAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFOQ7/PIx7f391/ORcWMZUEPPYYzoMB8G
# A1UdIwQYMBaAFO9vU0rp5AZ8esrikFb2L9RJ7MtOMA4GA1UdDwEB/wQEAwIHgDAW
# BgNVHSUBAf8EDDAKBggrBgEFBQcDCDCBlQYIKwYBBQUHAQEEgYgwgYUwJAYIKwYB
# BQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBdBggrBgEFBQcwAoZRaHR0
# cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1c3RlZEc0VGltZVN0
# YW1waW5nUlNBNDA5NlNIQTI1NjIwMjVDQTEuY3J0MF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNFRpbWVT
# dGFtcGluZ1JTQTQwOTZTSEEyNTYyMDI1Q0ExLmNybDAgBgNVHSAEGTAXMAgGBmeB
# DAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIBAGUqrfEcJwS5rmBB
# 7NEIRJ5jQHIh+OT2Ik/bNYulCrVvhREafBYF0RkP2AGr181o2YWPoSHz9iZEN/FP
# sLSTwVQWo2H62yGBvg7ouCODwrx6ULj6hYKqdT8wv2UV+Kbz/3ImZlJ7YXwBD9R0
# oU62PtgxOao872bOySCILdBghQ/ZLcdC8cbUUO75ZSpbh1oipOhcUT8lD8QAGB9l
# ctZTTOJM3pHfKBAEcxQFoHlt2s9sXoxFizTeHihsQyfFg5fxUFEp7W42fNBVN4ue
# LaceRf9Cq9ec1v5iQMWTFQa0xNqItH3CPFTG7aEQJmmrJTV3Qhtfparz+BW60OiM
# EgV5GWoBy4RVPRwqxv7Mk0Sy4QHs7v9y69NBqycz0BZwhB9WOfOu/CIJnzkQTwtS
# SpGGhLdjnQ4eBpjtP+XB3pQCtv4E5UCSDag6+iX8MmB10nfldPF9SVD7weCC3yXZ
# i/uuhqdwkgVxuiMFzGVFwYbQsiGnoa9F5AaAyBjFBtXVLcKtapnMG3VH3EmAp/js
# J3FVF3+d1SVDTmjFjLbNFZUWMXuZyvgLfgyPehwJVxwC+UpX2MSey2ueIu9THFVk
# T+um1vshETaWyQo8gmBto/m3acaP9QsuLj3FNwFlTxq25+T4QwX9xa6ILs84ZPvm
# povq90K8eWyG2N01c4IhSOxqt81nMIIGtDCCBJygAwIBAgIQDcesVwX/IZkuQEMi
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
# U0E0MDk2IFNIQTI1NiAyMDI1IENBMQIQCoDvGEuN8QWC0cR2p5V0aDANBglghkgB
# ZQMEAgEFAKCB0TAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwHAYJKoZIhvcN
# AQkFMQ8XDTI2MDcwNDA3NDE1NFowKwYLKoZIhvcNAQkQAgwxHDAaMBgwFgQU3WIw
# rIYKLTBr2jixaHlSMAf7QX4wLwYJKoZIhvcNAQkEMSIEIJPVhwFxnFZ5syYBA5XJ
# IDItUi9fScnY+RZ9jrbk4okvMDcGCyqGSIb3DQEJEAIvMSgwJjAkMCIEIEqgP6Is
# 11yExVyTj4KOZ2ucrsqzP+NtJpqjNPFGEQozMA0GCSqGSIb3DQEBAQUABIICAKNV
# nv7ywFgLPHfZnSWRJSxpYOfmCDFQzGBDbdbQbsKTOdr4E7dchgTq0ithgcWCjnOV
# ms+vD8LNmBGZIbIoCVV4cuTTC8J9ACMm6BcPeRpDApiR72/O366JOdgBFyhlIbuC
# 3qlAcBWSsDcI6oPZKeTqnoOR08MPLwWLo+aSZDdb2G3dpqGzJK1M1uB5T44QLddX
# iOLzGvHVzgsFMrdXnKfaD3oqGy4Q2aPTCn7zVr2xP5SsloxUL+BJ8+7KaxlPtcne
# rl9DHN/Imp1qLe2duaoIGge6hAP2oxqIKJBIzKzL4RIR3FC+03V5ABY8DPzaoDxp
# xgrAjRB/FVxZvLEQY5lzRDuzrgk50Acm/ELxn02870uWhNBxXeHymgMUU3tZkVbv
# XIsTEsgBwoR1hx153fgp3mCNBtFYiHNBZVrMd+pt326GUY4/CKwxeWWpy0nJJBJp
# SKpMVo2xJ8kQOaGF59vNitFNX17JyVJlWw0dMun9P4yLaOxvVWTYMpLcnfaouIof
# OmlAFkGUSMtlhkMyTrbyalXCg6ZXx0/k1TS2Pmd4EJYoKWOLIBAwCASkR+YVqAbI
# mrAdFbalgpJCIlSja4EmeQNQApe380WP0tOYf1aJJZZBUoerFQg22Up1H55y62lG
# tmTrnubu7p+tBsV05rKzufgkldECTdY15+94HcCl
# SIG # End signature block
