$TimeZone = "Romance Standard Time"

If ((Get-TimeZone).ID -ne $TimeZone)
{
Write-Output 'TimeZone is not configured'
Exit 1
}
else
{
Write-Output 'TimeZone is configured'
Exit 0
}