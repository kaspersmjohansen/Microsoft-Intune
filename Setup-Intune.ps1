Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -Verbose

# Install required Powershell Modules
# Install-Module AzureAD -Repository PSGallery -Scope CurrentUser -Force
Install-Module Microsoft.Graph.Intune -Repository PSGallery -Scope CurrentUser -Force
Install-Module Microsoft.Graph.Groups -Repository PSGallery -Scope CurrentUser -Force
# Install-Module AzureAD -Repository PSGallery -Scope CurrentUser -Force


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

# Connect-AzureAD -TenantID warlockstudy.net
Connect-MSGraph
Connect-AzureAD -TenantId warlockstudy.net

# Get Intuneconfig.json contents
$ConfigFilePath = "." + "\" + "IntuneConfig.json"
$config = Get-Content -Path $ConfigFilePath -Raw | ConvertFrom-Json

$IntuneGroupName = $config.IntuneConfig.GroupName
$IntuneGroupPrefix = $config.IntuneConfig.GroupPrefix
$IntuneGroupAffix = $config.IntuneConfig.GroupAffix
$IntuneAppGroup1 = $config.IntuneConfig.AppGroup1
$IntuneAppGroup2 = $config.IntuneConfig.AppGroup2
$IntuneAppGroup3 = $config.IntuneConfig.AppGroup3
$IntuneAppGroup4 = $config.IntuneConfig.AppGroup4
$IntuneAppGroup5 = $config.IntuneConfig.AppGroup5

# Create PoC group
$IntunePoCGroup = New-IntuneGroup $IntuneGroupName -Prefix $IntuneGroupPrefix -Affix $IntuneGroupAffix

# Create App groups
$IntunePoCApp1 = New-IntuneGroup -Name $IntuneAppGroup1 -Prefix $IntuneGroupPrefix -Affix $IntuneGroupAffix
$IntunePoCApp2 = New-IntuneGroup -Name $IntuneAppGroup2 -Prefix $IntuneGroupPrefix -Affix $IntuneGroupAffix
$IntunePoCApp3 = New-IntuneGroup -Name $IntuneAppGroup3 -Prefix $IntuneGroupPrefix -Affix $IntuneGroupAffix
$IntunePoCApp4 = New-IntuneGroup -Name $IntuneAppGroup4 -Prefix $IntuneGroupPrefix -Affix $IntuneGroupAffix
$IntunePoCApp5 = New-IntuneGroup -Name $IntuneAppGroup5 -Prefix $IntuneGroupPrefix -Affix $IntuneGroupAffix

# Add PoC group to App groups
Add-AzureADGroupMember -ObjectId $IntunePoCApp1.groupid -RefObjectId $IntunePoCGroup.groupId
Update-Groups -groupId $($IntunePoCGroup.groupId) -members $($IntunePoCApp1.groupid) -securityEnabled $true - #,$IntuneAppGroup2.groupid,$IntuneAppGroup3.groupid,$IntuneAppGroup4.groupid,$IntuneAppGroup5.groupid -securityEnabled $true

Update-Groups -groupId "bc997475-95b9-41dc-8622-ed23ea6fa496" -memberOf "12557b25-0f9d-4bda-9e1e-1d73afe80c52"

# Create Configuration Policies

# Create Compliance Policies

# Create Apps
