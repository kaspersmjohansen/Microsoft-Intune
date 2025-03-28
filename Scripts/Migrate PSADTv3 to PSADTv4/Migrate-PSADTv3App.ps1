<#PSScriptInfo
.SYNOPSIS
    Script to convert apps based on the Powershell AppDeploy Toolkit v3 framework to the Powershell AppDeploy Toolkit v4 
 
.DESCRIPTION
    This will convert apps based on the Powershell AppDeploy Toolkit v3 framework to the Powershell AppDeploy Toolkit v4 
    using the PSAppDeployToolkit.Tools module. 

    The PSAppDeployToolkit.Tools module is currently a pre-release module as per the Psappdeploytoolkit website
    https://psappdeploytoolkit.com/docs/getting-started/download#downloading-psappdeploytoolkittools

.PARAMETER SourceAppFolder
    A folder location with 1 or more PSADTv3 apps inside.

.PARAMETER NewAppFolder
    A folder location for the converted PSADTv4 app

.PARAMETER NewAppmediaFolderName
    Creates a containing/media folder inside the NewAppFolder

.PARAMETER NewAppLogPath
    Configures the PSADT and MSI log paths in the converted PSADTv4 app


.NOTES

.TODO
       
.AUTHOR
    Kasper Johansen 
    https://kasperjohansen.net

.COPYRIGHT
    Feel free to use this as much as you want :)

.RELEASENOTES
    16-03-2025 - 1.0.0 - Release to public

.CHANGELOG
    16-03-2025 - 1.0.0 - Release to public
#>
param(
    $SourceAppFolder,
    $NewAppFolder,
    $NewAppMediaFolderName,
    $NewAppLogPath
)

<#
If (!(Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) { Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null }
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

If (!($(Get-Module -ListAvailable PowerShellGet).Version -ge "2.2.5"))
{
    Write-Host "PowershellGet is at version $($(Get-Module -ListAvailable PowerShellGet)[0].Version)"
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
    Install-Module PowerShellGet -Force -Scope CurrentUser -AllowClobber
}
else 
{
    Write-Host "PowershellGet is at version $($(Get-Module -ListAvailable PowerShellGet)[0].Version)"
}
#>
If (!($(Get-Module -ListAvailable PowerShellGet).Version -ge "2.2.5"))
{
    Write-Host "PowershellGet is not the latest version" -ForegroundColor Yellow
    Write-Host "Execute the Install-Module PowerShellGet -Force -Scope CurrentUser -AllowClobber command to update the PowershellGet module" -ForegroundColor Yellow
    Break
}
else
{
    If (!(Get-Module -ListAvailable -Name PSAppDeployToolkit.Tools))
    {
        Install-Module PSAppDeployToolkit.Tools -Force -Scope CurrentUser -AllowPreRelease
        Import-Module PSAppDeployToolkit.Tools
    }
}

If (!(Test-Path -Path $NewAppFolder))
{
    Write-Host "New application folder does not exist: $NewAppFolder" -ForegroundColor Cyan
    New-Item -Path $NewAppFolder -ItemType Directory
}

# Get app source folder name 
$SourceAppFolderName = (Get-ChildItem -Path $SourceAppFolder).Name
ForEach ($AppFolder in $SourceAppFolderName)
{
    # Filter Deploy-Application.ps1 file and Files and SupportFiles folders
    Write-Host "Found PSADTv3 app: $AppFolder" -ForegroundColor Cyan
    $DeployApplicationFile = Get-ChildItem -Path "$SourceAppFolder\$AppFolder" -Filter "Deploy-Application.ps1" -Recurse
    $FilesFolder = Get-ChildItem -Path "$SourceAppFolder\$AppFolder" -Filter "Files" -Recurse -Directory
    $SupportFilesFolder = Get-ChildItem -Path "$SourceAppFolder\$AppFolder" -Filter "SupportFiles" -Recurse -Directory
    $AppDeployToolkitConfig = Get-ChildItem -Path "$SourceAppFolder\$AppFolder" -Filter "AppDeployToolkitConfig.xml" -Recurse
    
        # Create PSADTv4 template folder and convert PSADTv3 app to PSADTv4
        Write-Host "Create PSADTv4 app: $AppFolder" -ForegroundColor Cyan
        If (![string]::IsNullOrEmpty($NewAppMediaFolderName))
        {
            New-ADTTemplate -Destination $NewAppFolder -Name $AppFolder

            Write-Host "Converting PSADTv3 app to PSADTv4: $AppFolder" -ForegroundColor Cyan
            Convert-ADTDeployment -Path $($DeployApplicationFile.Fullname) -Destination "$NewAppFolder\$AppFolder" -Force

            Write-Host "Copy PSADTv3 app source files to PSADTv4 app location: $NewAppFolder\$AppFolder\Files" -ForegroundColor Cyan
            Copy-Item -Path "$($FilesFolder.FullName)\*" -Destination "$NewAppFolder\$AppFolder\Files" -Recurse
            Copy-Item -Path "$($SupportFilesFolder.FullName)\*" -Destination "$NewAppFolder\$AppFolder\SupportFiles" -Recurse

            # Configure toolkit and MSI log paths if defined in variable
            Write-Host "Update PSADTv4 app toolkit and MSI log paths" -ForegroundColor Cyan
            If (![string]::IsNullOrEmpty($NewAppLogPath))
            {
                (Get-Content -Path "$NewAppFolder\$AppFolder\Config\config.psd1").Replace('$envWinDir\Logs\Software',"$NewAppLogPath") | Set-Content -Path "$NewAppFolder\$AppFolder\Config\config.psd1" -Encoding "utf8"
            }
            
            # Create containing/media folder
            Write-Host "Create PSADTv4 app media folder: $NewAppFolder\$AppFolder\$NewAppMediaFolderName" -ForegroundColor Cyan
            New-Item -Path "$NewAppFolder\$AppFolder\$NewAppMediaFolderName" -ItemType Directory | Out-Null

            Write-Host "Move PSADTv4 app files and folders to media folder: $NewAppFolder\$AppFolder\$NewAppMediaFolderName" -ForegroundColor Cyan
            Get-Childitem -Path "$NewAppFolder\$AppFolder" -Exclude $NewAppMediaFolderName | Move-Item -Destination "$NewAppFolder\$AppFolder\$NewAppMediaFolderName"
        }
            else 
            {
                New-ADTTemplate -Destination $NewAppFolder -Name $AppFolder

                Write-Host "Converting PSADTv3 app to PSADTv4: $AppFolder" -ForegroundColor Cyan
                Convert-ADTDeployment -Path $($DeployApplicationFile.Fullname) -Destination "$NewAppFolder\$AppFolder" -Force

                Write-Host "Copy PSADTv3 app source files to PSADTv4 app location: $NewAppFolder\$AppFolder\Files" -ForegroundColor Cyan
                Copy-Item -Path "$($FilesFolder.FullName)\*" -Destination "$NewAppFolder\$AppFolder\Files" -Recurse
                Copy-Item -Path "$($SupportFilesFolder.FullName)\*" -Destination "$NewAppFolder\$AppFolder\SupportFiles" -Recurse

                # Create containing/media folder if defined in variable
                Write-Host "Update PSADTv4 app toolkit and MSI log paths" -ForegroundColor Cyan
                If (![string]::IsNullOrEmpty($NewAppLogPath))
                {
                    (Get-Content -Path "$NewAppFolder\$AppFolder\Config\config.psd1").Replace('$envWinDir\Logs\Software',"$NewAppLogPath") | Set-Content -Path "$NewAppFolder\$AppFolder\Config\config.psd1"
                }
            }
}