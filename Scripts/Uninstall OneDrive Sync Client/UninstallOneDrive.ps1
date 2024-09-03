param(
    [Parameter(Mandatory = $True)][ValidateSet("PerUser","PerMachine")]
    $InstallState
    )

$LoggedOnUser = (Get-WMIObject -ClassName Win32_ComputerSystem).Username
$LoggedOnUserSID = Get-LocalUser

    If ($InstallState -eq "PerUser")
    {
            $LogDir = "$env:USERPROFILE\OneDriveUninstall"+"-"+$(Get-Date -Format HHmmssyyyy)+".log"
            $OneDriveSetup = Get-Childitem -Path "C:\Users\$env:UserName\AppData\Local\Microsoft\OneDrive" -Recurse -Filter "OneDriveSetup.exe"
            $OneDriveSetupArgumentList = "/uninstall"
            $OneDriveSetupPath = $($OneDriveSetup[0].Fullname)
            Start-Transcript -Path $LogDir
            If (Test-Path -Path $OneDriveSetupPath -ErrorAction SilentlyContinue)
            {
                If (Get-Process -Name "OneDrive")
                {
                    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
                }
                    else 
                    {
                        Write-Host "OneDrive Sync Client is not running"
                    }
                        Start-Process -FilePath $OneDriveSetupPath -ArgumentList $OneDriveSetupArgumentList -Wait -NoNewWindow
            }
                else 
                {
                    Write-Host "OneDrive Sync Client PerUser install is not found"
                }

            Stop-Transcript
    }

    If ($InstallState -eq "PerMachine")
    {
                
                $LogDir = "$env:windir\Logs"+"-"+$(Get-Date -Format HHmmssyyyy)+".log"
                $OneDriveSetup = Get-Childitem -Path "$env:ProgramFiles\Microsoft OneDrive" -Recurse -Filter "OneDriveSetup.exe"
                $OneDriveSetupArgumentList = "/uninstall /alluser /allusers"
                $OneDriveSetupPath = $($OneDriveSetup.Fullname)
                Start-Transcript -Path $LogDir
                If (Test-Path -Path $OneDriveSetupPath)
                {
                    If (Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue)
                    {
                        Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
                    }
                        else 
                        {
                            Write-Host "OneDrive Sync Client is not running"
                        }
                            Start-Process -FilePath $OneDriveSetupPath -ArgumentList $OneDriveSetupArgumentList -Wait -NoNewWindow
                }
                    else 
                    {
                        Write-Host "OneDrive Sync Client PerMachine install is not found"
                    }

                Stop-Transcript
    }
