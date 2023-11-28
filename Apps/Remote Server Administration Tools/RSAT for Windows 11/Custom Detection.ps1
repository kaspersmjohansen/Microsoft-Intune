# Get RSAT Active Directory ADDS and Bitlocker status, enable if needed
If (!(Get-WindowsCapability -Online -Name 'Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0').state -eq 'Installed')
		{
			Exit 1
		}
		If (!(Get-WindowsCapability -Online -Name 'Rsat.CertificateServices.Tools~~~~0.0.1.0').state -eq 'Installed')
		{
			Exit 1
		}
        If (!(Get-WindowsCapability -Online -Name 'Rsat.DHCP.Tools~~~~0.0.1.0').state -eq 'Installed')
		{
			Exit 1
		}
        If (!(Get-WindowsCapability -Online -Name 'Rsat.Dns.Tools~~~~0.0.1.0').state -eq 'Installed')
		{
			Exit 1
		}
        If (!(Get-WindowsCapability -Online -Name 'Rsat.FileServices.Tools~~~~0.0.1.0').state -eq 'Installed')
		{
			Exit 1
		}
        If (!(Get-WindowsCapability -Online -Name 'Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0').state -eq 'Installed')
		{
			Exit 1
		}
        If (!(Get-WindowsCapability -Online -Name 'Rsat.RemoteDesktop.Services.Tools~~~~0.0.1.0').state -eq 'Installed')
		{
			Exit 1
		}
        If (!(Get-WindowsCapability -Online -Name 'Rsat.ServerManager.Tools~~~~0.0.1.0').state -eq 'Installed')
		{
			Exit 1
		}

Write-Host "Found it!"