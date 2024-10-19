<#PSScriptInfo
.SYNOPSIS
    Script to download application source files using Winget
 
.DESCRIPTION
    This script will get the latest application setup file from the public winget repository. 
    It uses a basic folder name to determine if an application setup files needs updating. 
    The script will create a folder structure of applications based on the PSADT framework and it will use an existing PSADT application folder if an application needs updating.
    If an application folder does not exist, a new one will be created based on the PSADT framework.
    Both new and existing app folders will be created in the BuildAppFolder location. This is done to separate new apps or apps that needs updating from existing production apps 

.PARAMETER CSVFile    

.PARAMETER SourceFolder    

.PARAMETER DestinationFolder

.PARAMETER ProductionAppFolder

.PARAMETER DestinationFolder
        
.EXAMPLE
    

.NOTES
            
.VERSION    

.AUTHOR
    Kasper Johansen 
    kmj@apento.com

.COMPANYNAME 
    Apento

.COPYRIGHT
    Feel free to use this as much as you want :)

.RELEASENOTES
    

.CHANGELOG
     
#>
param (
# Variables
$CSVFile = "$PSScriptRoot\AppsCSV.csv",
$SourceFolder = "$PSScriptRoot\Sources",
$BuildAppFolder = "$PSScriptRoot\_Build",
$ProductionAppFolder = "$PSScriptRoot\_Production",
$PSADTTemplateFolder = "$PSScriptRoot\PSADT Template 3.10.2"
)

# Import CSV file
Import-Csv -Path $CSVFile -Delimiter ";" | ForEach-Object {
    
    $Vendor = $_.Vendor
    $Product = $_.Product
    $Architecture = $_.Architecture
    $AppID = $_.AppID
    $Scope = $_.Scope
    $SourceFileFolder = "$Vendor $Product $Architecture"  
    
    # Get Winget application meta data and export to text file
    $WinGetAppMetaExport = "$SourceFolder\WinGetMetaExport-$AppID.txt"
    Start-Process -FilePath "winget.exe" -ArgumentList "show --id $AppID --exact --accept-source-agreements" -WindowStyle Hidden -Wait -RedirectStandardOutput $WinGetAppMetaExport
    $winGetOutput = Get-Content -Path $WinGetAppMetaExport
    Remove-Item -Path $WinGetAppMetaExport -Force

    # Get winget app version from meta data text fil
    $Version = $winGetOutput | Select-String -Pattern "version:" | ForEach-Object { $_.Line -replace '.*version:\s*(.*)', '$1' }

    # Create $SourceFolder\$SourceFileFolder if not exist
    If (!(Test-Path -Path "$SourceFolder\$SourceFileFolder"))
    {
        New-Item -Path $SourceFolder -name $SourceFileFolder -ItemType Directory | Out-Null
    }

    # Check for existing Winget app version if exist assume there is no new version of the app
    If (!(Test-Path -Path "$SourceFolder\$SourceFileFolder\$Version"))
    {
        Write-Host "$SourceFileFolder has been updated - Quickly, get it!" -ForegroundColor Yellow
        New-Item -Path "$SourceFolder\$SourceFileFolder" -name $Version -ItemType Directory
        # Get Winapp app source file based on the $Scope configuration
        If ($Scope -eq "None")
        {
            Start-Process -FilePath "winget.exe" -ArgumentList "download $AppID --exact --skip-dependencies --download-directory `"$SourceFolder\$SourceFileFolder\$Version`" --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
        }
        elseif ($Scope -eq "Machine"){
            Start-Process -FilePath "winget.exe" -ArgumentList "download $AppID --exact --skip-dependencies --download-directory `"$SourceFolder\$SourceFileFolder\$Version`" --scope $Scope --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
        }
        elseif ($Scope -eq "User"){
            Start-Process -FilePath "winget.exe" -ArgumentList "download $AppID --exact --skip-dependencies --download-directory `"$SourceFolder\$SourceFileFolder\$Version`" --scope $Scope --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
        }
        else {
            Start-Process -FilePath "winget.exe" -ArgumentList "download $AppID --exact --skip-dependencies --download-directory `"$SourceFolder\$SourceFileFolder\$Version`" --scope Machine --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
        }
    
        # Copy existing application folder sources files, if not exist create a new folder with PSADT framework files
        $AppFolder = "$Vendor $Product $Architecture $Version"
        $ProdApp = Get-ChildItem -Path $($ProductionAppFolder+"\"+$Vendor+" "+$Product+"*") | Select-Object -First 1
        If (!(Test-Path -Path "$BuildAppFolder\$AppFolder"))
        {
            New-Item -Path $BuildAppFolder -Name $AppFolder -ItemType Directory | Out-Null
                    
            If ($ProdApp)
            {
                Write-Host "Copying existing source files from $ProdApp" -ForegroundColor Yellow
                Write-Host "" 
                Copy-Item -Path "$ProdApp\*" -Recurse -Destination "$BuildAppFolder\$AppFolder" -Force
                Get-ChildItem -Path "$SourceFolder\$SourceFileFolder\$Version" | Where-Object {$_.extension -in ".exe",".msi"} | Copy-Item -Destination "$BuildAppFolder\$AppFolder\Media\Files" -Force
            }
            else
            {
                Write-Host "Copying source files from $PSADTTemplateFolder" -ForegroundColor Yellow
                Write-Host "" 
                Copy-Item -Path "$PSADTTemplateFolder\*" -Recurse -Destination "$BuildAppFolder\$AppFolder"
                Get-ChildItem -Path "$SourceFolder\$SourceFileFolder\$Version" | Where-Object {$_.extension -in ".exe",".msi"} | Copy-Item -Destination "$BuildAppFolder\$AppFolder\Media\Files"
            }
        }

    }
    else {
        Write-Host "$SourceFileFolder is already at latest version" -ForegroundColor Cyan
        Write-Host ""
    }

}