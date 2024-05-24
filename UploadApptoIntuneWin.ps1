# Set application source folder 
param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    [Parameter(Mandatory = $false)]
    [string]$OutputAppFolder = $SourcePath + "\" + "_Output",
    [Parameter(Mandatory = $True)]
    [string]$TenantID,
    [Parameter(Mandatory = $false)]
    [string]$InstallCommandLine = ".\ServiceUI.exe -Process:explorer.exe Deploy-Application.exe -DeploymentType install",
    [Parameter(Mandatory = $false)]
    [string]$UninstallCommandLine = ".\ServiceUI.exe -Process:explorer.exe Deploy-Application.exe -DeploymentType uninstall",
    [Parameter(Mandatory = $false)]
    [string]$SetupFile = "Deploy-Application.exe",
    [Parameter(Mandatory = $false)][ValidateSet("Short","UltraShort")]
    [string]$IntuneAppName = "Short"    
)

function Get-GroupId
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConnectClientID,
        [Parameter(Mandatory = $true)]
        [string]$ConnectClientSecret,
        $ConnectTenantID,
        [Parameter(Mandatory = $true)]
        [string]$GroupName
    )
        # Get JWT access token
        $Body =  @{
            Grant_Type    = "client_credentials"
            Scope         = "https://graph.microsoft.com/.default"
            Client_Id     = $ConnectClientID
            Client_Secret = $ConnectClientSecret
        }
        
        $Connection = Invoke-RestMethod `
            -Uri https://login.microsoftonline.com/$ConnectTenantID/oauth2/v2.0/token `
            -Method POST `
            -Body $Body
        
        #$Token = $connection.access_token
        $secureToken = ConvertTo-SecureString -String $($Connection.access_token) -AsPlainText -Force

        If (!(Get-Module -ListAvailable -Name Microsoft.Graph.Groups)) { Install-Module Microsoft.Graph.Groups -Force -Scope CurrentUser | Import-Module Microsoft.Graph.Groups | Out-Null }
        Connect-MgGraph -AccessToken $secureToken -NoWelcome

            Get-MgGroup -Filter "DisplayName eq '$GroupName'" | Select-Object Id
}

# Get contents of the source path folder
$AppSources = Get-ChildItem -Path $SourcePath -Directory -ErrorAction Stop

#Region module import
# Install required modules
Write-Host "Importing required Powershell modules, please wait" -ForegroundColor Cyan
If (!(Get-Module -ListAvailable -Name NuGet)) { Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null }
If (!(Get-Module -ListAvailable -Name IntuneWin32App)) { Install-Module IntuneWin32App -Force -Scope CurrentUser | Import-Module IntuneWin32App | Out-Null }
If (!(Get-Module -ListAvailable -Name Microsoft.Graph.Intune)) { Install-Module Microsoft.Graph.Intune -Force -Scope CurrentUser | Import-Module Microsoft.Graph.Intune | Out-Null }
#Endregion Module Import

# App registration konfiguration
$ClientID = "58d9e836-34b7-4537-bd98-5ccd930dde2a"
$ClientSecret = "KVB8Q~ftIBu2t.hxybTfZ0YZpXwke3gmQp3HVcrQ"
Connect-MSIntuneGraph -TenantID $TenantID -ClientID $ClientID -ClientSecret $ClientSecret | Out-Null

# Connect to MSGraph
# Connect-MSIntuneGraph -TenantID $TenantID

#Region convert app to Win32 App
ForEach ($App in $AppSources)
{
    # Set media app root and app media variables
    $AppRootPath = $App.Fullname
    $MediaPath = $AppRootPath  + "\" + "Media"
    $ConfigFilePath = $AppRootPath  + "\" + "AppConfig.json"
        
    # Check if Media folder exists, if not, app is not packaged to intunewin
    If ((Test-Path -Path $MediaPath) -and (Test-Path -Path $ConfigFilePath))
    {
        # Set app variables based on AppConfig.json file
        $config = Get-Content -Path $ConfigFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $Vendor = $config.AppConfig.Vendor
        $Product = $config.AppConfig.Product
        $Version = $config.AppConfig.Version
        $Architecture = $config.AppConfig.Architecture
        
        # Set IntuneWin package folder anem
        $PackageFolderName = $Vendor + " " + $Product + " " + $Architecture + " " + $Version

            # Set Intune app name
            If ($IntuneAppName -eq "Short")
            {
                $AppName = $Vendor + " " + $Product        
            }

            If ($IntuneAppName -eq "UltraShort")
            {
                $AppName = $Product        
            }

            # Set output folder variable
            $OutputFolder = $OutputAppFolder + "\" + $PackageFolderName

                #Region Import intunewin to Intune
                # Update existing Win32 app
                # Get current app information
                $App = Get-IntuneWin32App | Where-Object {$_.DisplayName -eq "$AppName"}
                
                # Skip app, if app exist in Intune and is the same version as source app
                If ($App -and $App.displayVersion -eq $Version)                
                {
                    Write-Verbose "$AppName is the latest version" -Verbose
                }
                    # Update app, if app exist in Intune and version is older than source app 
                    If ($App -and $App.displayVersion -ne $Version)
                    {
                        Write-Verbose "Updating $($App.DisplayName)" -Verbose

                        # Create Output folder, if not exist
                        If (!(Test-Path $OutputAppFolder))
                        {
                            New-Item -Path $OutputAppFolder -ItemType Directory
                        }
                            If (!(Test-Path -Path $OutputFolder))
                            {
                                New-Item -Path $OutputFolder -ItemType Directory
                            }

                            # Create intunewin file
                            $Win32AppPackage = New-IntuneWin32AppPackage -SourceFolder $MediaPath -SetupFile $SetupFile -OutputFolder $OutputFolder -Verbose

                            # Get .intunewin package location
                            $IntuneWinFile = $Win32AppPackage.Path

                                # Update existing app in Intune with new intunewin file and version information
                                $AppID = $App.ID
                                Update-IntuneWin32AppPackageFile -ID $AppID -FilePath $IntuneWinFile -ErrorAction Stop
                                Set-IntuneWin32App -ID $AppID -AppVersion $Version
                    }
                        # Import app, if app does not exist in Intune
                        If (!($App))
                        {
                            #Write-Host "Importing $AppNameShort to Intune"
                            If (!(Test-Path $OutputAppFolder))
                            {
                                New-Item -Path $OutputAppFolder -ItemType Directory
                            }
                                If (!(Test-Path -Path $OutputFolder))
                                {
                                    New-Item -Path $OutputFolder -ItemType Directory
                                }
                                    # Create intunewin file
                                    $Win32AppPackage = New-IntuneWin32AppPackage -SourceFolder $MediaPath -SetupFile $SetupFile -OutputFolder $OutputFolder -Verbose

                                    # Get .intunewin package location
                                    $IntuneWinFile = $Win32AppPackage.Path

                                    # Set app variables
                                    $Architecture = $config.AppConfig.Architecture
                                    $DetectionRuleScript = $config.AppConfig.DetectionScript
                                    $RequirementRuleScript = $config.AppConfig.RequirementScript
                                    $Icon = $config.AppConfig.Icon
                                    [string]$AvailableGroup = $config.AppConfig.AvailableGroup
                                    [string]$RequiredGroup = $config.AppConfig.RequiredGroup

                                    # Create requirement rule
                                    If ($Architecture -eq "x86x64")
                                    {
                                        $Architecture = "All"
                                    }
                                    $RequirementRule = New-IntuneWin32AppRequirementRule -Architecture $Architecture -MinimumSupportedWindowsRelease "W10_22H2"

                                    # Create script based requirement rule
                                    If ($RequirementRuleScript)
                                    {
                                        $RequirementRuleScript = New-IntuneWin32AppRequirementRuleScript -ScriptFile $($AppRootPath + "\" + $RequirementRuleScript) -StringOutputDataType -StringValue "ok" -ScriptContext "system" -StringComparisonOperator "equal"
                                    }

                                    # Create script based detection rule
                                    $DetectionRule = New-IntuneWin32AppDetectionRuleScript -ScriptFile $($AppRootPath + "\" + $DetectionRuleScript)

                                    # Convert image file to icon
                                    $Icon = New-IntuneWin32AppIcon -FilePath $($AppRootPath + "\" + $Icon)

                                    # Create custom return code
                                    # $ReturnCode = New-IntuneWin32AppReturnCode -ReturnCode 1337 -Type "retry"

                                    # Set install and uninstall command line
                                    # $InstallCommandLine = ".\ServiceUI.exe -Process:explorer.exe Deploy-Application.exe -DeploymentType install"
                                    # $UninstallCommandLine = ".\ServiceUI.exe -Process:explorer.exe Deploy-Application.exe -DeploymentType uninstall"

                                    #-AdditionalRequirementRule $RequirementRuleScript
                                    If ($RequirementRuleScript)
                                    {
                                        $RequirementRuleScript = New-IntuneWin32AppRequirementRuleScript -ScriptFile $($AppRootPath + "\" + $RequirementRuleScript) -StringOutputDataType -StringValue "ok" -ScriptContext "system" -StringComparisonOperator "equal"
                                        $Win32App = Add-IntuneWin32App -FilePath "$IntuneWinFile" -DisplayName $AppName -Description $AppName -AppVersion $Version -Publisher $Vendor -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -RequirementRule $RequirementRule -Icon $Icon -Verbose -UseAzCopy -AdditionalRequirementRule $RequirementRuleScript
                                    } else
                                        {
                                            $Win32App = Add-IntuneWin32App -FilePath "$IntuneWinFile" -DisplayName $AppName -Description $AppName -AppVersion $Version -Publisher $Vendor -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -RequirementRule $RequirementRule -Icon $Icon -Verbose -UseAzCopy
                                        }
                                                        
                                        # Configure a Intune Available group if specified                
                                        If (($AvailableGroup -eq "AllDevices" -or $AvailableGroup -eq "AllUsers")) #-and ![string]::IsNullOrEmpty($AvailableGroup))
                                        {   
                                            Add-IntuneWin32AppAssignmentAllUsers -ID $Win32App.id -Intent "available" -Notification "showAll" -Verbose
                                        }
                                            elseif (![string]::IsNullOrEmpty($AvailableGroup))
                                            {
                                                Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $AvailableGroup -Intent "available" -Notification "showAll" -Verbose    
                                            }
                                            else
                                            {}
                                                If (($RequiredGroup -eq "AllDevices" -or $RequiredGroup -eq "AllUsers")) #-and ![string]::IsNullOrEmpty($RequiredGroup))
                                                {
                                                    Add-IntuneWin32AppAssignmentAllDevices -ID $Win32App.id -Intent "required" -Notification "showAll" -Verbose                                                    
                                                }
                                                    elseif (![string]::IsNullOrEmpty($RequiredGroup))
                                                    {
                                                        Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $RequiredGroup -Intent "required" -Notification "showAll" -Verbose    
                                                    }
                                                    else
                                                    {}
                        } 
                #Endregion Import intunewin to Intune
    }
    else {
            If (!(Test-Path -Path $MediaPath))
            {
                Write-Host "$MediaPath is not found" -ForegroundColor Red
            }

            If (!(Test-Path -Path $ConfigFilePath))
            {
                Write-Host "$ConfigFilePath is not found" -ForegroundColor Red
            }
    }
}
#Endregion convert app to Win32 App