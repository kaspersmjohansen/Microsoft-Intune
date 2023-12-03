$CSVFile = ".\AppsCSV.csv"
$DownloadFolder = ".\Sources"

Import-Csv -Path $CSVFile -Delimiter ";" | ForEach-Object{
    $AppName = $_.AppName
    $AppID = $_.AppID
    $AppArchitecture = $_.AppArchitecture
    
    $WinGetAppMetaExport = "$DownloadFolder\WinGetMetaExport-$AppName.txt"
    Start-Process -FilePath "winget.exe" -ArgumentList "show --id $AppID --exact --accept-source-agreements" -WindowStyle Hidden -Wait -RedirectStandardOutput $WinGetAppMetaExport
    $winGetOutput = Get-Content -Path $WinGetAppMetaExport
    # Remove-Item -Path $WinGetAppMetaExport -Force

    $Version = $winGetOutput | Select-String -Pattern "version:" | ForEach-Object { $_.Line -replace '.*version:\s*(.*)', '$1' }

    If (!(Test-Path -Path "$DownloadFolder\$AppName"))
    {
        New-Item -Path $DownloadFolder -name $AppName -ItemType Directory
    }

    If (!(Test-Path -Path "$DownloadFolder\$AppName\$Version"))
    {
        New-Item -Path "$DownloadFolder\$AppName" -name $Version -ItemType Directory
        Start-Process -FilePath "winget.exe" -ArgumentList "download $AppID --exact --download-directory `"$DownloadFolder\$AppName\$Version`" --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
    }
    else {
        Write-Host "$AppName is already at latest version"
    }
}