$AppxPackageName = "Microsoft.OutlookForWindows"
If (Get-AppxPackage -Name $AppxPackageName)
{
    Write-Host "$AppxPackageName found."
    Exit 1
}
else
{
    Write-Host "$AppxPackageName not found."
    Exit 0
}