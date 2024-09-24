$RegistryKeys = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$Language =  "da-DK"
$M365Apps = "^Microsoft 365.*$($language)\.proof$"

$M365AppsCheck = $RegistryKeys | Where-Object { $_.GetValue("DisplayName") -match $M365Apps }
if ($M365AppsCheck) {
    Write-Output "Proofing Tools $($language) Detected"
	Exit 0
   }
else {
    Write-Output "Proofing Tools $($language) not Detected"
    Exit 1
}