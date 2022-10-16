Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -Verbose

# Install required Powershell Modules
# Install-Module AzureAD -Repository PSGallery -Scope CurrentUser -Force
Install-Module Microsoft.Graph.Intune -Repository -Scope CurrentUser -Force

# Function to create Intune groups
function New-IntuneGroup
{
    param(
        [Parameter(Mandatory=$true)]
         $Name,
         [string]$Prefix,
         [string]$Affix
    )
        Import-Module -Name Microsoft.Graph.Intune -ErrorAction Stop
        ForEach ($Group in $Name)
        {
            If ($Prefix -and [string]::IsNullOrEmpty($Affix))
            {
                $GroupName = $Prefix + $Group
                New-Groups -displayName "$GroupName" -mailEnabled $false -mailNickname "$GroupName" -securityEnabled $true    
            }            
                If ($Affix -and [string]::IsNullOrEmpty($Prefix))
                {
                    $GroupName = $Group + $Affix
                    New-Groups -displayName "$GroupName" -mailEnabled $false -mailNickname "$GroupName" -securityEnabled $true     
                }
                    If ($Prefix -and $Affix)
                    {
                        $GroupName = $Prefix + $Group + $Affix
                        New-Groups -displayName "$GroupName" -mailEnabled $false -mailNickname "$GroupName" -securityEnabled $true     
                    }                    
                        If ([string]::IsNullOrEmpty($Prefix) -and [string]::IsNullOrEmpty($Affix))
                        {
                            New-Groups -displayName "$Group" -mailEnabled $false -mailNickname "$Group" -securityEnabled $true
                        }
        }

}

# Get Intuneconfig.json contents
$ConfigFilePath = "." + "\" + "IntuneConfig.json"
$config = Get-Content -Path $ConfigFilePath -Raw | ConvertFrom-Json

# Connect-AzureAD -TenantID warlockstudy.net
get-help Connect-MSGraph

# Create PoC Group
New-IntuneGroup -
# Create App Groups
# Create Apps
