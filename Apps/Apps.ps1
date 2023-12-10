$CSVFile = "$PSScriptRoot\AppsCSV.csv"
$SourceFolder = "$PSScriptRoot\Sources"
$DestinationFolder = "$PSScriptRoot"

Import-Csv -Path $CSVFile -Delimiter ";" | ForEach-Object{
    $Vendor = $_.Vendor
    $Product = $_.Product
    $AppID = $_.AppID
    $Architecture = $_.Architecture
    
    $AppFolder = "$Vendor $Product $Architecture"
    
    $WinGetAppMetaExport = "$SourceFolder\WinGetMetaExport-$AppName.txt"
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
        Start-Process -FilePath "winget.exe" -ArgumentList "download $AppID --exact --download-directory `"$SourceFolder\$AppFolder\$Version`" --scope machine --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
    }
    else {
        Write-Host "$AppFolder is already at latest version" -ForegroundColor Cyan
        Write-Host ""
    }

    If (!(Test-Path -Path "$DestinationFolder\$AppFolder"))
    {
        New-Item -Path $DestinationFolder -Name $AppFolder -ItemType Directory
        New-Item -Path "$DestinationFolder\$AppFolder" -Name Media -ItemType Directory
        Copy-Item -Path "$DestinationFolder\PSADT Template\*" -Recurse -Destination "$DestinationFolder\$AppFolder\Media"
        Copy-Item -Path "$DestinationFolder\DetectionScript.ps1" -Destination "$DestinationFolder\$AppFolder"
    }
}