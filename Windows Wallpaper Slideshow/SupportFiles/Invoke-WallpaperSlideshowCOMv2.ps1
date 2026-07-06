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