<#
.SYNOPSIS
    Sets the Windows network profile to Private when a specific domain resolves to a local IP address.

.DESCRIPTION
    Resolves the specified domain name using DNS only (hosts file, LLMNR and NetBIOS are bypassed).
    If any A record falls within a private RFC 1918 range (10.0.0.0/8, 172.16.0.0/12 or 192.168.0.0/16),
    the script finds the network interface used to reach that address and changes its network profile
    from Public to Private.

    Only the interface routing to the resolved address is changed. Networks that are already Private
    or DomainAuthenticated are left untouched. If the domain cannot be resolved, or resolves to a
    non-local address, the script exits without making changes.

.PARAMETER DomainName
    The fully qualified domain name to resolve, for example intranet.contoso.local.

.EXAMPLE
    .\Set-PrivateNetworkProfile.ps1 -DomainName intranet.contoso.local

    Sets the network profile to Private if intranet.contoso.local resolves to a local IP address.

.EXAMPLE
    .\Set-PrivateNetworkProfile.ps1 -DomainName intranet.contoso.local -WhatIf

    Shows which network profile would be changed without applying the change.

.NOTES
    Author:   Kasper Johansen - kasperjohansen.net
    Version:  1.0
    Requires: Windows PowerShell 5.1 or later, run as administrator
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$DomainName
)

$ErrorActionPreference = 'Stop'

try {
    $DnsParams = @{
        Name         = $DomainName
        Type         = 'A'
        DnsOnly      = $true
        QuickTimeout = $true
    }
    $Addresses = Resolve-DnsName @DnsParams | Where-Object Type -eq 'A' | Select-Object -ExpandProperty IPAddress
}
catch {
    Write-Output "Could not resolve $DomainName"
    exit 0
}

$LocalAddress = $Addresses | Where-Object { $_ -match '^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.)' } | Select-Object -First 1
if (-not $LocalAddress) {
    Write-Output "$DomainName does not resolve to a local IP"
    exit 0
}

$InterfaceIndex = (Find-NetRoute -RemoteIPAddress $LocalAddress | Select-Object -First 1).InterfaceIndex
$ConnectionProfile = Get-NetConnectionProfile -InterfaceIndex $InterfaceIndex

if ($ConnectionProfile.NetworkCategory -eq 'Public') {
    if ($PSCmdlet.ShouldProcess($ConnectionProfile.Name, 'Set network profile to Private')) {
        $ProfileParams = @{
            InterfaceIndex  = $InterfaceIndex
            NetworkCategory = 'Private'
        }
        Set-NetConnectionProfile @ProfileParams
        Write-Output "Network '$($ConnectionProfile.Name)' set to Private"
    }
}
else {
    Write-Output "Network '$($ConnectionProfile.Name)' is already $($ConnectionProfile.NetworkCategory)"
}
