#Parameters

#LogPath
$DefaultLogPath = "C:\Windows\Logs\IntuneDeployment\DesktopBackground"

#Background Image Screen
$BackgroundPictureRemotePath = $null
$BackgroundPictureLocalPath = "C:\Windows\Web\Wallpaper\Windows"
$BackgroundPictureName = "Wallpaper.jpg"

#LockScreen Image
$LockScreenPictureRemotePath = $null
$LockScreenPictureLocalPath = $null
$LockScreenPictureName = $null

#Settings
$OnlyCopyFilesTODekstop = $False # Set to $True if only want to copy the files to the local desktop.
$OverrideExistingBackground = $true # Set to $True if you  want to overrride the existing background a user has chosen. The user can change it back afterwards.
$PreventUserToChangeBackground = $false # Set to $True if you want to prevent user to change Background
$PreventUsertoChangeTheme = $false # Set to $True if you want to prevent user to change Theme

#Copy wallpaper image file
Copy-Item -Path "$PSScriptRoot\*.jpg" -Destination $BackgroundPictureLocalPath -Force -Verbose

Function GenerateFolder($path) {
    $global:foldPath = $null
    foreach($foldername in $path.split("\")) {
        $global:foldPath += ($foldername+"\")
        if (!(Test-Path $global:foldPath)){
            New-Item -ItemType Directory -Path $global:foldPath
            
        }
    }
}

$TestPath = test-path $DefaultLogPath
if (!($TestPath)){GenerateFolder $DefaultLogPath}

Start-Transcript -Path "$DefaultLogPath\DesktopImageScript.txt" -Append

Function Set-WallPaper {
 
<#
 
    .SYNOPSIS
    Applies a specified wallpaper to the current user's desktop
    
    .PARAMETER Image
    Provide the exact path to the image
 
    .PARAMETER Style
    Provide wallpaper style (Example: Fill, Fit, Stretch, Tile, Center, or Span)
  
    .EXAMPLE
    Set-WallPaper -Image "C:\Wallpaper\Default.jpg"
    Set-WallPaper -Image "C:\Wallpaper\Background.jpg" -Style Fit
  
#>
 
param (
    [parameter(Mandatory=$True)]
    # Provide path to image
    [string]$Image,
    # Provide wallpaper style that you would like applied
    [parameter(Mandatory=$False)]
    [ValidateSet('Fill', 'Fit', 'Stretch', 'Tile', 'Center', 'Span')]
    [string]$Style
)
 
$WallpaperStyle = Switch ($Style) {
  
    "Fill" {"10"}
    "Fit" {"6"}
    "Stretch" {"2"}
    "Tile" {"0"}
    "Center" {"0"}
    "Span" {"22"}
  
}
 
If($Style -eq "Tile") {
 
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\" -Name TileWallpaper -PropertyType String -Value 1 -Force
 
}
Else {
 
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies" -Name TileWallpaper -PropertyType String -Value 0 -Force
 
}
 
Add-Type -TypeDefinition @" 
using System; 
using System.Runtime.InteropServices;
  
public class Params
{ 
    [DllImport("User32.dll",CharSet=CharSet.Unicode)] 
    public static extern int SystemParametersInfo (Int32 uAction, 
                                                   Int32 uParam, 
                                                   String lpvParam, 
                                                   Int32 fuWinIni);
}
"@ 
  
    $SPI_SETDESKWALLPAPER = 0x0014
    $UpdateIniFile = 0x01
    $SendChangeEvent = 0x02
  
    $fWinIni = $UpdateIniFile -bor $SendChangeEvent
  
    $ret = [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $fWinIni)
}
 

 #Downloading Background Image
 if($BackgroundPictureRemotePath){
 
 Write-Output "Download Desktop Wallpaper"
  invoke-WebRequest -Uri $BackgroundPictureRemotePath -OutFile "$BackgroundPictureLocalPath\$BackgroundPictureName"
  Start-Sleep -Seconds 5
 }else{
 
 Write-Output "Unable to find Desktop Wallpaper on remote location"

 }

 #Downloading Lock Screen Image
 if($LockScreenPictureRemotePath){
 
 Write-Output "Download Lock Screen Image"
  invoke-WebRequest -Uri $LockScreenPictureRemotePath -OutFile "$BackgroundPictureLocalPath\$BackgroundPictureName"
  Start-Sleep -Seconds 5
 }else{
 
 Write-Output "Unable to find Lock Screen Image on remote location"

 }
 


 if($OnlyCopyFilesTODekstop){
 
 Write-Output "CopyOnly parameter is set to true, Will not enforce background image or any other stuff"
 Stop-Transcript
 
 break
 

 }
 

#Set Desktop Wallpaper
write-output "Applying background for new users."
Set-WallPaper -Image "$BackgroundPictureLocalPath\$BackgroundPictureName" -Style Stretch




#Prevent user to change Wallpaper

if($PreventUserToChangeBackground){
    
    Write-Output "Setting regkey to prevent user to change background image"
    If (!(Test-Path -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop")) { New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" -Force }
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" -Name NoChangingWallPaper -PropertyType dword -Value 1 -Force
}




#Prevent user to change Theme
if ($PreventUsertoChangeTheme){

    Write-Output "Setting regkey to prevent user to change Themes"
    If (!(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer")) { New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Force }
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name NoThemesTab -PropertyType dword -Value 1 -Force


}


#Set Lockscreen Image
if($LockScreenPictureName){

    Write-Output "Setting Lockscreen Image"
    If (!(Test-Path -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization")) { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Force }
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name LockScreenImage -PropertyType String -Value $LockScreenPictureLocalPath -Force
}

#Override existing background image
 if($OverrideExistingBackground){
 
 Write-Output "Creating task to override existing wallpaper"
 
 
	Start-Transcript -Path $(Join-Path -Path $DefaultLogPath -ChildPath "DesktopBackgroundScheduledTask.log")

	###########################################################################################
	# Get the current script path and content and save it to the client
	###########################################################################################

	$currentScript = Get-Content -Path $($PSCommandPath)

    

	#$schtaskScript = $currentScript[(0) .. ($currentScript.IndexOf("#!SCHTASKCOMESHERE!#") - 1)]

    $schtaskScript = @'

        Function Set-WallPaper {
 
    <#
 
        .SYNOPSIS
        Applies a specified wallpaper to the current user's desktop
    
        .PARAMETER Image
        Provide the exact path to the image
 
        .PARAMETER Style
        Provide wallpaper style (Example: Fill, Fit, Stretch, Tile, Center, or Span)
  
        .EXAMPLE
        Set-WallPaper -Image "C:\Wallpaper\Default.jpg"
        Set-WallPaper -Image "C:\Wallpaper\Background.jpg" -Style Fit
  
    #>
 
    param (
        [parameter(Mandatory=$True)]
        # Provide path to image
        [string]$Image,
        # Provide wallpaper style that you would like applied
        [parameter(Mandatory=$False)]
        [ValidateSet('Fill', 'Fit', 'Stretch', 'Tile', 'Center', 'Span')]
        [string]$Style
    )
 
    $WallpaperStyle = Switch ($Style) {
  
        "Fill" {"10"}
        "Fit" {"6"}
        "Stretch" {"2"}
        "Tile" {"0"}
        "Center" {"0"}
        "Span" {"22"}
  
    }
 
    If($Style -eq "Tile") {
 
        New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force -ErrorAction Ignore
        New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\" -Name TileWallpaper -PropertyType String -Value 1 -Force -ErrorAction Ignore
 
    }
    Else {
 
        New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force -ErrorAction Ignore
        New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies" -Name TileWallpaper -PropertyType String -Value 0 -Force -ErrorAction Ignore
 
    }
 
    Add-Type -TypeDefinition @" 
    using System; 
    using System.Runtime.InteropServices;
  
    public class Params
    { 
        [DllImport("User32.dll",CharSet=CharSet.Unicode)] 
        public static extern int SystemParametersInfo (Int32 uAction, 
                                                       Int32 uParam, 
                                                       String lpvParam, 
                                                       Int32 fuWinIni);
    }
"@ 
  
        $SPI_SETDESKWALLPAPER = 0x0014
        $UpdateIniFile = 0x01
        $SendChangeEvent = 0x02
  
        $fWinIni = $UpdateIniFile -bor $SendChangeEvent
  
        $ret = [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $fWinIni)
    }
    
    $BackgroundPictureLocalPath = "C:\Windows\Web\Wallpaper\Windows"
    $BackgroundPictureName = "Wallpaper.jpg"

    Set-WallPaper -Image "$BackgroundPictureLocalPath\$BackgroundPictureName" -Style Stretch
'@

	$scriptSavePath = $(Join-Path -Path $DefaultLogPath -ChildPath "DesktopBackground-generator")

	if (-not (Test-Path $scriptSavePath)) {

		New-Item -ItemType Directory -Path $scriptSavePath -Force
	}

	$scriptSavePathName = "DesktopBackgroundOverrideexisting.ps1"

	$scriptPath = $(Join-Path -Path $scriptSavePath -ChildPath $scriptSavePathName)

	$schtaskScript | Out-File -FilePath $scriptPath -Force

	###########################################################################################
	# Create dummy vbscript to hide PowerShell Window popping up at logon
	###########################################################################################

	$vbsDummyScript = "
	Dim shell,fso,file
	Set shell=CreateObject(`"WScript.Shell`")
	Set fso=CreateObject(`"Scripting.FileSystemObject`")
	strPath=WScript.Arguments.Item(0)
	If fso.FileExists(strPath) Then
		set file=fso.GetFile(strPath)
		strCMD=`"powershell -nologo -executionpolicy ByPass -command `" & Chr(34) & `"&{`" &_
		file.ShortPath & `"}`" & Chr(34)
		shell.Run strCMD,0
	End If
	"

	$scriptSavePathName = "DesktopBackground-VBSHelper.vbs"

	$dummyScriptPath = $(Join-Path -Path $scriptSavePath -ChildPath $scriptSavePathName)

	$vbsDummyScript | Out-File -FilePath $dummyScriptPath -Force

	$wscriptPath = Join-Path $env:SystemRoot -ChildPath "System32\wscript.exe"

	###########################################################################################
	# Register a scheduled task to run for all users and execute the script on logon
	###########################################################################################

	$schtaskName = "Change user Desktop background"
	$schtaskDescription = "This task will override the desktop background the user has selected with the pre-defined once. This task should only run once."

	$trigger = New-ScheduledTaskTrigger -AtLogOn
	#Execute task in users context
	$principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" -Id "Author"
	#call the vbscript helper and pass the PosH script as argument
	$action = New-ScheduledTaskAction -Execute $wscriptPath -Argument "`"$dummyScriptPath`" `"$scriptPath`""
	$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

	$null = Register-ScheduledTask -TaskName $schtaskName -Trigger $trigger -Action $action  -Principal $principal -Settings $settings -Description $schtaskDescription -Force

	Start-ScheduledTask -TaskName $schtaskName
    Start-Sleep -Seconds 10
    Disable-ScheduledTask -TaskName $schtaskName
    #Unregister-ScheduledTask -TaskName $schtaskName -Confirm:$false
    #Remove-Item -Path $scriptPath -force
    #Remove-Item -Path $dummyScriptPath -force


 }

Stop-Transcript
