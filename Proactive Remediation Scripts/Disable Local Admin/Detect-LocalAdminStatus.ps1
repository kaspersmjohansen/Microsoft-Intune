$LocalAdmin = Get-LocalUser -Name Administrator
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