$LocalAdmin = Get-LocalUser -Name Administrator
$LocalAdminStatus = $LocalAdmin.Enabled

If ($LocalAdminStatus -eq "True")
{
Write-Output "$LocalAdmin is enabled"
Disable-LocalUser -Name $LocalAdmin.Name
Exit 0
}
else
{
Write-Output "$LocalAdmin is disabled"
Exit 0
}