$Company = "virtualwarlock.net"

$WallpaperRegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
$WallpaperImageValue = "C:\Windows\Web\Wallpaper\Windows\Wallpaper1.jpeg"
$DestinationDirectory = "C:\Windows\Web\Wallpaper\Windows"

#$DesktopPath = "DesktopImagePath"
#$DesktopStatus = "DesktopImageStatus"
#$DesktopUrl = "DesktopImageUrl"

#$StatusValue = "1"

# $url = "https://publichostedwebsite.com/image.jpeg"


If (!(Test-Path $WallpaperRegKeyPath))
{
	New-Item -Path $WallpaperRegKeyPath -Force | Out-Null
}

Copy-Item -Path "$PSScriptRoot\*.jpg" -Destination $DestinationDirectory -Force
<#
If ((Test-Path -Path $directory) -eq $false)
{
	New-Item -Path $directory -ItemType directory
}
#>

#$wc = New-Object System.Net.WebClient
#$wc.DownloadFile($url, $DesktopImageValue)

New-ItemProperty -Path $WallpaperRegKeyPath -Name 'DesktopImageStatus' -Value '1' -PropertyType dword -Force | Out-Null
New-ItemProperty -Path $WallpaperRegKeyPath -Name 'DesktopImagePath' -Value $WallpaperImageValue -PropertyType string -Force | Out-Null
New-ItemProperty -Path $WallpaperRegKeyPath -Name 'DesktopImageUrl' -Value $WallpaperImageValue -PropertyType string -Force | Out-Null

#RUNDLL32.EXE USER32.DLL, UpdatePerUserSystemParameters 1, True

If (!(Test-Path "HKLM:\SOFTWARE\$Company"))
{
	New-Item -Path "HKLM:\SOFTWARE\$Company" -Force | Out-Null
}

