
$CustomerName = "Morsø Kommune"

$RootFolder = "C:\Users\KasperSvenMozartJoha\OneDrive - APENTO\Kunder"
$CustomerFolder = $RootFolder + "\" + $CustomerName
$AppsFolder = $CustomerFolder + "\" + "Intune" + "\" + "Apps"
$PSADTtemplate = $AppsFolder + "\" + "PSADT Template"

$SourceApps = Get-ChildItem -Path "$CustomerFolder\Intune\Source"
$AppName = $SourceApps.Name
ForEach ($App in $AppName)
{
    If (!(Test-Path -Path $($AppsFolder + "\" + $App)))
    {
        New-Item -Path $($AppsFolder + "\" + $App) -ItemType Directory
    }
    Copy-Item -Path "$PSADTtemplate\Media" -Recurse -Destination $($AppsFolder + "\" + $App)
    Copy-Item -Path "$PSADTtemplate\DetectionScript.ps1" -Destination $($AppsFolder + "\" + $App)
}