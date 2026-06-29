#Requires -Version 5.1
<#
.SYNOPSIS
    Exports all Intune platform scripts from a tenant to local .ps1 files.

.DESCRIPTION
    Connects to Microsoft Graph and retrieves all deviceManagementScripts from the
    beta endpoint. Each script's base64-encoded content is decoded and saved to disk.

.PARAMETER OutputPath
    Destination folder for exported scripts. Created if it does not exist.

.PARAMETER TenantId
    Optional. Tenant ID or domain to target a specific tenant via Connect-MgGraph.

.EXAMPLE
    .\Export-IntunePlatformScripts.ps1 -OutputPath C:\Temp\IntunePlatformScripts

.EXAMPLE
    .\Export-IntunePlatformScripts.ps1 -OutputPath C:\Temp\IntunePlatformScripts -TenantId contoso.onmicrosoft.com

.NOTES
    Author  : Kasper M. Johansen | Apento
    Email   : kmj@apento.com
    Version : 1.0
    Date    : 2026-06-29
    Requires: Microsoft.Graph.Authentication
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [string]$OutputPath,

    [Parameter()]
    [string]$TenantId
)

$ErrorActionPreference = 'Stop'

# Connect to Microsoft Graph
$connectParams = @{
    Scopes    = 'DeviceManagementConfiguration.Read.All'
    NoWelcome = $true
}
if ($TenantId) { $connectParams['TenantId'] = $TenantId }
Connect-MgGraph @connectParams

# Ensure output folder exists
if (-not (Test-Path -LiteralPath $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath | Out-Null
    Write-Verbose "Created output folder: $OutputPath"
}

# Retrieve full platform script list with pagination
$scripts = [System.Collections.Generic.List[object]]::new()
$uri = 'https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts'

do {
    $response = Invoke-MgGraphRequest -Method GET -Uri $uri
    foreach ($item in $response.value) { $scripts.Add($item) }
    $uri = $response.'@odata.nextLink'
} while ($uri)

Write-Host "Found $($scripts.Count) platform script(s)"

$exported = 0
$skipped  = 0

foreach ($script in $scripts) {
    # Fetch individual record - scriptContent is not returned in the list call
    $detail = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($script.id)"

    if (-not $detail.scriptContent) {
        Write-Warning "Skipping '$($script.displayName)' - no script content returned"
        $skipped++
        continue
    }

    $decoded  = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($detail.scriptContent))
    $safeName = $script.displayName -replace '[\\/:*?"<>|]', '_'
    $filePath = Join-Path -Path $OutputPath -ChildPath "$safeName.ps1"

    # Avoid silent overwrite on display name collision
    if (Test-Path -LiteralPath $filePath) {
        $filePath = Join-Path -Path $OutputPath -ChildPath "$($safeName)_$($script.id).ps1"
    }

    if ($PSCmdlet.ShouldProcess($filePath, 'Write script')) {
        [System.IO.File]::WriteAllText($filePath, $decoded, [System.Text.UTF8Encoding]::new($false))
        Write-Host "Exported: $(Split-Path -Path $filePath -Leaf)"
        $exported++
    }
}

Write-Host "`nExport complete - Exported: $exported | Skipped: $skipped | Output: $OutputPath"