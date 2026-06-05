#Requires -Version 5.1
<#
.SYNOPSIS
    Applies wallpaper slideshow settings via the IDesktopWallpaper COM interface.

.DESCRIPTION
    Must run as the interactive user. Called by Deploy-Application.ps1 via
    Execute-ProcessAsUser to apply slideshow settings to the active desktop session.

.PARAMETER ImageFolder
    Path to the folder containing wallpaper images.

.PARAMETER PosCode
    DESKTOP_WALLPAPER_POSITION value.
    0=Center, 1=Tile, 2=Stretch, 3=Fit, 4=Fill, 5=Span

.PARAMETER IntervalMs
    Slideshow interval in milliseconds.

.PARAMETER Shuffle
    0 = sequential, 1 = random.

.EXAMPLE
    .\Invoke-WallpaperSlideshowCOM.ps1 -ImageFolder "C:\Wallpapers" -PosCode 4 -IntervalMs 1800000 -Shuffle 1
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ImageFolder,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 5)]
    [int]$PosCode,

    [Parameter(Mandatory = $true)]
    [int]$IntervalMs,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 1)]
    [int]$Shuffle
)

$ErrorActionPreference = 'Stop'

Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class WallpaperSlideshow
{
    static readonly Guid CLSID_DesktopWallpaper =
        new Guid("C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD");

    [ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B"),
     InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IDesktopWallpaper
    {
        void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID,
                          [MarshalAs(UnmanagedType.LPWStr)] string wallpaper);
        [return: MarshalAs(UnmanagedType.LPWStr)]
        string GetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID);
        [return: MarshalAs(UnmanagedType.LPWStr)]
        string GetMonitorDevicePathAt(uint monitorIndex);
        [return: MarshalAs(UnmanagedType.U4)]
        uint GetMonitorDevicePathCount();
        [return: MarshalAs(UnmanagedType.Struct)]
        object GetMonitorRECT([MarshalAs(UnmanagedType.LPWStr)] string monitorID);
        void SetBackgroundColor(uint color);
        uint GetBackgroundColor();
        void SetPosition(int position);
        int  GetPosition();
        void SetSlideshow(IntPtr items);
        IntPtr GetSlideshow();
        void SetSlideshowOptions(int options, uint slideshowTick);
        void GetSlideshowOptions(out int options, out uint slideshowTick);
        void AdvanceSlideshow([MarshalAs(UnmanagedType.LPWStr)] string monitorID, int direction);
        int  GetStatus();
        bool Enable(bool enable);
    }

    const int DSO_SHUFFLEIMAGES = 0x01;

    [DllImport("shell32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern int SHCreateItemFromParsingName(
        [MarshalAs(UnmanagedType.LPWStr)] string pszPath,
        IntPtr pbc, ref Guid riid, out IntPtr ppv);

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    static extern int SHCreateShellItemArrayFromShellItem(IntPtr psi,
        ref Guid riid, out IntPtr ppv);

    public static void Apply(string folderPath, int positionCode,
                             uint intervalMs, bool shuffle)
    {
        var type = Type.GetTypeFromCLSID(CLSID_DesktopWallpaper);
        var idw  = (IDesktopWallpaper)Activator.CreateInstance(type);

        Guid IID_IShellItem      = new Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE");
        Guid IID_IShellItemArray = new Guid("B63EA76D-1F85-456F-A19C-48159EFA858B");

        IntPtr pShellItem;
        int hr = SHCreateItemFromParsingName(folderPath, IntPtr.Zero,
                                             ref IID_IShellItem, out pShellItem);
        if (hr != 0) Marshal.ThrowExceptionForHR(hr);

        IntPtr pItemArray;
        hr = SHCreateShellItemArrayFromShellItem(pShellItem,
                                                 ref IID_IShellItemArray, out pItemArray);
        if (hr != 0) Marshal.ThrowExceptionForHR(hr);

        idw.SetSlideshow(pItemArray);
        idw.SetPosition(positionCode);
        idw.SetSlideshowOptions(shuffle ? DSO_SHUFFLEIMAGES : 0, intervalMs);

        Marshal.ReleaseComObject(idw);
    }
}
'@

Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class ShellRefresh
{
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
        uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);

    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);

    public static readonly IntPtr HWND_BROADCAST  = new IntPtr(0xffff);
    public const uint  WM_SETTINGCHANGE            = 0x001A;
    public const uint  SMTO_ABORTIFHUNG           = 0x0002;
    public const int   SPI_SETDESKWALLPAPER        = 20;
    public const int   SPIF_UPDATEINIFILE          = 0x01;
    public const int   SPIF_SENDCHANGE             = 0x02;
    public const uint  SHCNE_ASSOCCHANGED          = 0x08000000;
    public const uint  SHCNF_IDLIST                = 0x0000;
}
'@

try {
    [WallpaperSlideshow]::Apply($ImageFolder, $PosCode, [uint32]$IntervalMs, [bool]$Shuffle)
}
catch {
    Write-Warning "IDesktopWallpaper COM call failed: $($_.Exception.Message)"
}

# Signal the shell to reload the desktop wallpaper from the registry.
# Runs unconditionally so it covers both a successful COM apply and the catch path.
[ShellRefresh]::SystemParametersInfo(
    [ShellRefresh]::SPI_SETDESKWALLPAPER, 0, '',
    [ShellRefresh]::SPIF_UPDATEINIFILE -bor [ShellRefresh]::SPIF_SENDCHANGE
) | Out-Null

# Broadcast WM_SETTINGCHANGE so Explorer and the shell process the new settings
$broadcastResult = [UIntPtr]::Zero
[ShellRefresh]::SendMessageTimeout(
    [ShellRefresh]::HWND_BROADCAST,
    [ShellRefresh]::WM_SETTINGCHANGE,
    [UIntPtr]::Zero,
    'Policy',
    [ShellRefresh]::SMTO_ABORTIFHUNG,
    5000,
    [ref]$broadcastResult
) | Out-Null

# Notify the shell that associations have changed, which triggers a full shell refresh
# on Windows 10 and 11 without restarting Explorer
[ShellRefresh]::SHChangeNotify(
    [ShellRefresh]::SHCNE_ASSOCCHANGED,
    [ShellRefresh]::SHCNF_IDLIST,
    [IntPtr]::Zero,
    [IntPtr]::Zero
)
# SIG # Begin signature block
# MIIeegYJKoZIhvcNAQcCoIIeazCCHmcCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCDBzkx1HO91gIV
# hsjXLXAEDUOAETa4Fed0VFAHg3hAUKCCA9YwggPSMIICuqADAgECAgg7LtLmDulW
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
# FTAvBgkqhkiG9w0BCQQxIgQgDTcHADzOnDDx2aAVa5VeG9tZpH6alaeTY8YYZmeP
# ZOMwTAYKKwYBBAGCNwIBDDE+MDygIoAgAFIAbwBiAG8AcABhAGMAawAgAHAAYQBj
# AGsAYQBnAGWhFoAUaHR0cHM6Ly9yb2JvcGFjay5jb20wDQYJKoZIhvcNAQEBBQAE
# ggEAjN5gV+9OVNbLkvgAJ3NQ88l7Pg41i4HjyocLBNYRFXEaykStPAh177vX6gfq
# 28IqtEEvs1FRhnx/P1xNeAfKqj9Fo4Uq4a1/xD2uRUf4M1dB3eGdG7/Bg6R9Nd/7
# ZsJ7wyY9CK0W7ItfIcNO21ELiZKNFiV6OhMLBOmS9oZYd2y1qgAu+trBMHuIrWe+
# itPuD/QRfNgP7RikuAfHvWWxBH/g9advi4vhGClCnMf21F40pqGru1DSEBx40ato
# ptJRU26M9O5FGffrHxq/gDrb44Xw9RTQda6PuRsiih4onY4yTOKoG5HVAnLX6B1t
# 3LOdkuRHTUv58aoTfLrayFJEx6GCF3cwghdzBgorBgEEAYI3AwMBMYIXYzCCF18G
# CSqGSIb3DQEHAqCCF1AwghdMAgEDMQ8wDQYJYIZIAWUDBAIBBQAweAYLKoZIhvcN
# AQkQAQSgaQRnMGUCAQEGCWCGSAGG/WwHATAxMA0GCWCGSAFlAwQCAQUABCBjvcgn
# kubzWR5qHpuXLVPQmf3oZtSGh4+87TnWk30qAgIRAKGPH29z1KSr9IaCmMq0+oAY
# DzIwMjYwNjA1MTIzMjA4WqCCEzowggbtMIIE1aADAgECAhAKgO8YS43xBYLRxHan
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
# AQkFMQ8XDTI2MDYwNTEyMzIwOFowKwYLKoZIhvcNAQkQAgwxHDAaMBgwFgQU3WIw
# rIYKLTBr2jixaHlSMAf7QX4wLwYJKoZIhvcNAQkEMSIEIHZ9tvzHw2hrP93avo3G
# KTvATSZnGolLVtLWYaYpEqL2MDcGCyqGSIb3DQEJEAIvMSgwJjAkMCIEIEqgP6Is
# 11yExVyTj4KOZ2ucrsqzP+NtJpqjNPFGEQozMA0GCSqGSIb3DQEBAQUABIICAByP
# tOMCu9E8gEX44g3+IsTJJyVEqsik7z1eB/6TIS/aEjm18yN+qBWRlBSnEmZZBnvd
# kU5UdNnEuDzxE0opxuf+VGdaFDt/WhjIWYjrjjMkxERQaDdH/VRXb7uPmv9Hf4Bd
# /AUhdxqGoXsfqsM2nxf/c80xLVisWJqQSkkbil7Vsd0dRlW6PQuGoASKKDpxeZ3j
# YHRhp4UuC7FjNIMu5w95yztv5oKlrbxo9zZQ6cfC4Ribk6ekdxgfP5rN6xBH6C70
# 4wZ1T+vO+a4yo/kTV3tT6wPkIb8qRHxvq9aD5ZORBK4EwmJiuFdbxcnViOiRDDQY
# HDrVRN77uX4yjwFdo4UNSQ6iODlR5R3XCTv4AOvui/aX0RX07JgKarUppo5Jz2YN
# 504U2jcn1ee0gIye2dCG6EY+R7jjzknq8mhGC4xyOQn+YizJRSZ+4zNIYt7dsuNh
# zR/UOo0PKbUs4YpCwzVGrO4HkeEWHm0fl163/NfmsdM7emas07GqXYrKUC7qH4oL
# Ocd8XyitmE5MmYzdO1CZ1ufa+4vhjPghMnZvh8YBoF6p+LN21gCf2e/ATGHntdme
# DB/5X4GH3cl//U0K/KQiwHkhNSeAycCjcOlboRpr4uXXZjpOTK7FWpMGwewnYoqn
# V6w6CfVfgyqr9D3KAF9nF0yHOj1ZxdOvMW81Dep5
# SIG # End signature block
