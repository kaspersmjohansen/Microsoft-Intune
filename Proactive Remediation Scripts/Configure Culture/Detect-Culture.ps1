$Culture = "da-DK"
If ((Get-Culture).Name -ne $Culture)
{
Write-Output "$Culture culture is not configured"
Exit 1
}
else
{
Write-Output "$Culture culture is configured"
Exit 0
}
