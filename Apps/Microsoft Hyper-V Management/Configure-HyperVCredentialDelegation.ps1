$HyperVServers = "srvhv01.johansen.local"

# Configure network profile to private
$NetworkProfile = Get-NetConnectionProfile
If ($NetworkProfile.NetworkCategory -eq "Public")
{
    $EthernetIndex = (Get-NetConnectionProfile | where {$_.InterfaceAlias -eq "Ethernet"}).InterfaceIndex
    Set-NetConnectionProfile -InterfaceIndex $EthernetIndex -NetworkCategory Private
}

# Enable PSRemoting
Enable-PSRemoting

# Configure Hyper-V Servers as trusted hosts
ForEach ($Server in $HyperVServers)
{
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$Server" -Force
    Enable-WSManCredSSP -Role client -DelegateComputer "$Server" -Force
}

# Configure registry values to allow credential delegation
If (!(Test-Path -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation))
{
    New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\" -Name 'CredentialsDelegation'
}

New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\" -Name 'AllowFreshCredentialsWhenNTLMOnly'
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\" -Name 'AllowFreshCredentialsWhenNTLMOnly' -PropertyType DWord -Value "00000001"
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\" -Name 'ConcatenateDefaults_AllowFreshNTLMOnly' -PropertyType DWord -Value "00000001"
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\" -Name 'AllowFreshCredentials'

ForEach ($Server in $HyperVServers)
{
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentialsWhenNTLMOnly\" -Name '1' -Value "wsman/$Server"
}