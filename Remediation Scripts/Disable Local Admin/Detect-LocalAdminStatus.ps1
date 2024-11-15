$LocalAdmin = Get-LocalUser | Where-Object {$_.SID -like "*-500"}
$LocalAdminStatus = $LocalAdmin.Enabled

If ($LocalAdminStatus -eq "True")
{
Write-Output "$LocalAdmin is enabled"
Exit 1
}
else
{
Write-Output "$LocalAdmin is disabled"
Exit 0
}