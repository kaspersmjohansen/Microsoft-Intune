$HomelocationID = "61"

If ((Get-WinHomeLocation).GeoId -ne $HomelocationID)
{
Write-Output 'Home Location is not configured'
Exit 1
}
else
{
Write-Output 'Home Location is configured'
Exit 0
}