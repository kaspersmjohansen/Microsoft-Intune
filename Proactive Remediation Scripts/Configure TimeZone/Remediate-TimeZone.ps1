$TimeZone = "Romance Standard Time"

If ((Get-TimeZone).ID -ne $TimeZone)
{
Write-Output 'TimeZone is not configured'
Set-TimeZone -Id "Romance Standard Time"
Exit 0
}
else
{
Write-Output 'TimeZone is configured'
Exit 0
}