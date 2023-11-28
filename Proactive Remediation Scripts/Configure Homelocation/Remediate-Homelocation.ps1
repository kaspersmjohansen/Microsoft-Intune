$HomelocationID = "61"

If ((Get-WinHomeLocation).GeoId -ne $Homelocation)
{
Write-Output 'Home Location is not configured'
Set-WinHomeLocation -GeoId "61"
Exit 0
}
else
{
Write-Output 'Home Location is configured'
Exit 0
}