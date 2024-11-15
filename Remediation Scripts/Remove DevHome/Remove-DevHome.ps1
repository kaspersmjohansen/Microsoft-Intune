$AppxPackageName = "Microsoft.Windows.DevHome"
try
{
    Get-AppxPackage -Name $AppxPackageName | Remove-AppxPackage -ErrorAction Stop
    Write-Host "$AppxPackageName successfully removed."
}
catch
{
    Write-Error "Error removing $AppxPackageName."
    Write-Host "Encountered Error:"$_.Exception.Message
}