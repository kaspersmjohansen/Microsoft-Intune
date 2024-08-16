$CSVFile = "$PSScriptRoot\AppsCSV.csv"
$SourceFolder = "$PSScriptRoot\Sources"
$DestinationFolder = "$PSScriptRoot\_Build"
$ProductionAppFolder = "$PSScriptRoot\_Production"
$PSADTTemplateFolder = "$PSScriptRoot\PSADT Template 3.10.1"

Import-Csv -Path $CSVFile -Delimiter ";" | ForEach-Object {
    
    $Vendor = $_.Vendor
    $Product = $_.Product
    $Architecture = $_.Architecture
    $AppID = $_.AppID
    $Scope = $_.Scope
    $SourceFileFolder = "$Vendor $Product $Architecture"  
    
    $WinGetAppMetaExport = "$SourceFolder\WinGetMetaExport-$AppID.txt"
    Start-Process -FilePath "winget.exe" -ArgumentList "show --id $AppID --exact --accept-source-agreements" -WindowStyle Hidden -Wait -RedirectStandardOutput $WinGetAppMetaExport
    $winGetOutput = Get-Content -Path $WinGetAppMetaExport
    Remove-Item -Path $WinGetAppMetaExport -Force

    $Version = $winGetOutput | Select-String -Pattern "version:" | ForEach-Object { $_.Line -replace '.*version:\s*(.*)', '$1' }

    If (!(Test-Path -Path "$SourceFolder\$SourceFileFolder"))
    {
        New-Item -Path $SourceFolder -name $SourceFileFolder -ItemType Directory
    }

    If (!(Test-Path -Path "$SourceFolder\$SourceFileFolder\$Version"))
    {
        New-Item -Path "$SourceFolder\$SourceFileFolder" -name $Version -ItemType Directory
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
    
        $AppFolder = "$Vendor $Product $Architecture $Version"
        $ProdApp = Get-ChildItem -Path $($ProductionAppFolder+"\"+$Vendor+" "+$Product+"*") | Select-Object -First 1
        If (!(Test-Path -Path "$DestinationFolder\$AppFolder"))
        {
            New-Item -Path $DestinationFolder -Name $AppFolder -ItemType Directory
            #New-Item -Path "$DestinationFolder\$AppFolder" -Name Media -ItemType Directory
            
            If ($ProdApp)
            {
                Copy-Item -Path "$ProdApp\*" -Recurse -Destination "$DestinationFolder\$AppFolder" -Force
                Get-ChildItem -Path "$SourceFolder\$SourceFileFolder\$Version" | Where-Object {$_.extension -in ".exe",".msi"} | Copy-Item -Destination "$DestinationFolder\$AppFolder\Media\Files" -Force
            }
            else
            {
                Copy-Item -Path "$PSADTTemplateFolder\*" -Recurse -Destination "$DestinationFolder\$AppFolder"
                #Copy-Item -Path "$DestinationFolder\DetectionScript.ps1" -Destination "$DestinationFolder\$AppFolder"
                Get-ChildItem -Path "$SourceFolder\$SourceFileFolder\$Version" | Where-Object {$_.extension -in ".exe",".msi"} | Copy-Item -Destination "$DestinationFolder\$AppFolder\Media\Files"
            }
        }

    }
    else {
        Write-Host "$SourceFileFolder is already at latest version" -ForegroundColor Cyan
        Write-Host ""
    }

}