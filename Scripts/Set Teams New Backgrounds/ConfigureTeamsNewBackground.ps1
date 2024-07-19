# Path to Backgrounds Teams 2.1 Client
# %localappdata%\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\Uploads
# Required Image Size: 1920x1080 keep aspect ratio
# Preview: 220x158 keep aspect ratio
# Requires ResizeImage PowerShell Module: https://github.com/RonildoSouza/ResizeImageModulePS
#
# Place the script in the same directory as the desired background images
#
####
Function GenerateFolder($path) {
    $global:foldPath = $null
    foreach($foldername in $path.split("\")) {
        $global:foldPath += ($foldername+"\")
        if (!(Test-Path $global:foldPath)){
            New-Item -ItemType Directory -Path $global:foldPath
            
        }
    }
}

#LogPath
$DefaultLogPath = "$env:USERPROFILE"

$TestPath = test-path $DefaultLogPath
if (!($TestPath)){GenerateFolder $DefaultLogPath}
Start-Transcript -Path "$DefaultLogPath\TeamsImageScript.txt" -Append

<#
function Get-ScriptDirectory {
    Split-Path -Parent $PSCommandPath
}
#>

$outputPath = "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\Uploads"
If (!(Test-Path -Path $outputPath))
{
    New-Item -Path $outputPath -ItemType Directory -Force
}

if (!(Get-InstalledModule -Name ResizeImageModule -ErrorAction SilentlyContinue )) {
    Write-Host "ResizeImageModule not installed, installing..." -ForegroundColor Yellow
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Name  ResizeImageModule -Scope CurrentUser
    Write-Host "Import Module ResizeImageModule"
    Import-Module  ResizeImageModule
}
else {
    if (!(Get-Module -Name ResizeImageModule)) {
        Write-Host "Import ResizeImageModule"
        Import-Module ResizeImageModule 
    }
    else {
        Write-Host "ResizeImageModule already imported"
    }
}

$images = Get-ChildItem *.jpg
foreach($image in $images){
    $guid = New-Guid
    Write-Host "Creating Background"
    Resize-Image -InputFile $image -Width 1920 -Height 1080 -ProportionalResize $true -OutputFile $outputPath\$guid.jpg
    Write-Host "Creating Background Thumbnail"
    $ThumbName = "$guid`_thumb.jpg"
    Resize-Image -InputFile $image -Width 220 -Height 158 -ProportionalResize $true -OutputFile $outputPath\$ThumbName
}

New-Item -Path $env:USERPROFILE -Name "Teamsbackground-v1.tag" -ItemType File

Stop-Transcript