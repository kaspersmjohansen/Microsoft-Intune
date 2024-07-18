$CSVFile = "$PSScriptRoot\AppsCSV.csv"
$SourceFolder = "$PSScriptRoot\Sources"
$DestinationFolder = "$PSScriptRoot\_Production"
$PSADTTemplateFolder = "$PSScriptRoot\PSADT Template 3.10.1"

Import-Csv -Path $CSVFile -Delimiter ";" | ForEach-Object {
    
    $Vendor = $_.Vendor
    $Product = $_.Product
    $Architecture = $_.Architecture
    $AppID = $_.AppID
    $Scope = $_.Scope
    $AppFolder = "$Vendor $Product $Architecture"
    
    
    $WinGetAppMetaExport = "$SourceFolder\WinGetMetaExport-$AppID.txt"
    Start-Process -FilePath "winget.exe" -ArgumentList "show --id $AppID --exact --accept-source-agreements" -WindowStyle Hidden -Wait -RedirectStandardOutput $WinGetAppMetaExport
    $winGetOutput = Get-Content -Path $WinGetAppMetaExport
    Remove-Item -Path $WinGetAppMetaExport -Force

    $Version = $winGetOutput | Select-String -Pattern "version:" | ForEach-Object { $_.Line -replace '.*version:\s*(.*)', '$1' }

    If (!(Test-Path -Path "$SourceFolder\$AppFolder"))
    {
        New-Item -Path $SourceFolder -name $AppFolder -ItemType Directory
    }

    If (!(Test-Path -Path "$SourceFolder\$AppFolder\$Version"))
    {
        New-Item -Path "$SourceFolder\$AppFolder" -name $Version -ItemType Directory
        If ($Scope -eq "None")
        {
            Start-Process -FilePath "winget.exe" -ArgumentList "download $AppID --exact --skip-dependencies --download-directory `"$SourceFolder\$AppFolder\$Version`" --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
        }
        elseif ($Scope -eq "Machine"){
            Start-Process -FilePath "winget.exe" -ArgumentList "download $AppID --exact --skip-dependencies --download-directory `"$SourceFolder\$AppFolder\$Version`" --scope $Scope --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
        }
        elseif ($Scope -eq "User"){
            Start-Process -FilePath "winget.exe" -ArgumentList "download $AppID --exact --skip-dependencies --download-directory `"$SourceFolder\$AppFolder\$Version`" --scope $Scope --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
        }
        else {
            Start-Process -FilePath "winget.exe" -ArgumentList "download $AppID --exact --skip-dependencies --download-directory `"$SourceFolder\$AppFolder\$Version`" --scope Machine --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
        }
    }
    else {
        Write-Host "$AppFolder is already at latest version" -ForegroundColor Cyan
        Write-Host ""
    }

    If (!(Test-Path -Path "$DestinationFolder\$AppFolder"))
    {
        New-Item -Path $DestinationFolder -Name $AppFolder -ItemType Directory
        #New-Item -Path "$DestinationFolder\$AppFolder" -Name Media -ItemType Directory
        Copy-Item -Path "$PSADTTemplateFolder\*" -Recurse -Destination "$DestinationFolder\$AppFolder"
        #Copy-Item -Path "$DestinationFolder\DetectionScript.ps1" -Destination "$DestinationFolder\$AppFolder"
        Get-ChildItem -Path "$SourceFolder\$AppFolder\$Version" | Where-Object {$_.extension -in ".exe",".msi"} | Copy-Item -Destination "$DestinationFolder\$AppFolder\Media\Files"
    }
}