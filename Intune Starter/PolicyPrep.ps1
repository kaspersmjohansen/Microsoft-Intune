#Requires -version 5.1
<#
.NAME
    PolicyPrep

.SYNOPSIS
    Renaming of Intune JSON policy files.

.DESCRIPTION
    This script renames Intune JSON policy files, both the file itself and the displayname property within the file.
    The IntuneManagement tool by Micke-K, has been used to export the Intune policies to JSON files.
    
    The IntuneManagement tool is available here:
    https://github.com/Micke-K/IntuneManagement
    
.NOTES

    Author:             Kasper Johansen
    Website:            https://virtualwarlock.net
    Last modified Date: 22-10-2022

#>

param (
        [Parameter(Mandatory = $true)]
        [string]$NamePrefix,
        [Parameter(Mandatory = $true)]
        [string]$TenantID,
        [string]$SourcePath = "$env:PSSCRIPTROOT\Source",
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
)

<#
$TemplatePrefix = "VWL"
$SourcePath = "C:\temp\PolicyExport\Source"
$DestinationPath = "C:\temp\PolicyExport\Destination"
$NamePrefix = "TMP"
$TenantID = "72239bb3-9a09-4dde-8a96-3c4b629327f7"
#>

#Region - Functions
# Function to copy the policy JSON files form a source folder to at destination folder
function Copy-Json-Files {
    If (!(Test-Path -Path $DestinationPath))
    {
        try {
            Write-Host "$DestinationPath not found" -ForegroundColor Cyan
            New-Item -Path $DestinationPath -ItemType Directory -ErrorAction Stop | Out-Null
            Write-Host "$DestinationPath successfully created" -ForegroundColor Cyan
        }
        catch {
            Write-Host "Could not create $DestinationPath"
            Write-Warning $Error[0]
            Break
        }
    }
            Write-Host "Copying policy files" -ForegroundColor Cyan
            Copy-Item -Path "$SourcePath\*" -Recurse -Destination $DestinationPath
}

# function to rename the JSON policy file.
function Rename-Json-Files {
    $DestinationPath = "\\?\$DestinationPath"
    $Jsons = Get-ChildItem -LiteralPath $DestinationPath -Filter *.json -Recurse
    
        ForEach ($Json in $Jsons){
            $ParentFolderPath = $Json.Directory
            $NewName = $Json.Name -Replace "$TemplatePrefix","$NamePrefix"
            Write-Host "Renaming JSON policy files" -ForegroundColor Cyan
            Rename-Item -Path "$ParentFolderPath\$($Json.Name)" "$NewName"        
        }
}


<#
# function to rename the policy. It updates the Displayname property within the JSON file
function Update-Policy-Name {
    $Jsons = Get-ChildItem -Path $DestinationPath -Filter "$NamePrefix*.json" -Exclude *_Settings.json -Recurse
        ForEach ($Json in $Jsons){
            $config = Get-Content -Path $Json.Fullname -Raw | ConvertFrom-Json
                If ($config.Name)                {
                        $config.name = $Json.Name.TrimEnd(".json")
                }
                else {
                        $config.displayname = $Json.Name.TrimEnd(".json")
                }
            Write-Host "Renaming policy" -ForegroundColor Cyan            
            $config | ConvertTo-Json -Depth 25 | Out-File $($Json.FullName)
        }
}
#>

<#
# Function to do a search/replace of the tenant ID 
function Search-Replace-String {
    $Jsons = Get-ChildItem -Path $DestinationPath -Filter "$NamePrefix*.json" -Exclude *_Settings.json -Recurse
        ForEach ($Json in $Jsons){
            $config = Get-Content -Path $Json.Fullname -Raw | ConvertFrom-Json
            Write-Host "Replacing the tenant ID value" -ForegroundColor Cyan
            $config -replace "xxTENANTIDxx","$TenantID" | Out-File $($Json.FullName)
        }
}
#>

#EndRegion -Functions

#Region - script execution
Copy-Json-Files

Rename-Json-Files

# Search-Replace-String

#EndRegion - script execution