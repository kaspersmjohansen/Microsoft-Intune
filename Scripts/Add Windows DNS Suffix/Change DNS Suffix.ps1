$DNSSuffixDomain = "johansen.local"
$ConnectionSuffix = (Get-DnsClient | Where-Object -Property InterfaceAlias -Match Ethernet).ConnectionSpecificSuffix
Set-DnsClientGlobalSetting -SuffixSearchList @("$ConnectionSuffix","$DNSSuffixDomain")