param(
        [Parameter(Mandatory = $True)]
        [string]$PackageName,
        [string]$PackageParams,
        [Parameter(Mandatory = $True)][ValidateSet("Install","Uninstall")]
        [string]$Mode,
        [string]$LogDir = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"       
)

# Check if chocolatey is installed
If (Get-Command -Name choco -ErrorAction SilentlyContinue)
{
    Write-Host "Chocolatey is installed"
}
    else 
    {
        Write-Host "Chocolatey is not installed"
        Write-Host "Installing Chocolatey - Please wait...!"
        try
        {
            If (!(Test-Path $LogDir))
            {
                New-Item -Path $LogDir -ItemType Directory
            }
                Set-ExecutionPolicy -Scope Process Bypass -Force
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
            catch 
            {
                Write-Host "$_.Exception.Message"
                $Error[0] | OutFile $($LogDir+"\"+"ChocolateyInstallError"+".log")
                Exit 1
            }
    }

If ($Mode -eq "Install")
{
    # Create log folder
    If (!(Test-Path $LogDir))
    {
        New-Item -Path $LogDir -ItemType Directory
    }
        # Configure log filename 
        [string]$AppLogFile = $($PackageName+"-"+$(Get-Date -format MMddyyHHmmss)+"-"+"Install"+".log")
        [string]$AppLog = "$($LogDir+"\"+$AppLogFile)"
        [string]$ChocoLogFile = $($PackageName+"-"+$(Get-Date -format MMddyyHHmmss)+"-"+"Choco-Install"+".log")
        [string]$ChocoLog = "$($LogDir+"\"+$ChocoLogFile)"

        # Install Chocolatey app package
        Write-Host "Installing Chocolatey package - $PackageName"
        If (!([string]::IsNullOrEmpty($PackageParams)))
        {
            Start-Process -Wait -FilePath "$env:SYSTEMROOT\system32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-Command `"& {choco install $PackageName -y --params $PackageParams --log-file $AppLog}`"" -NoNewWindow -RedirectStandardOutput $ChocoLog
        }
            else
            {
                Start-Process -Wait -FilePath "$env:SYSTEMROOT\system32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-Command `"& {choco install $PackageName -y --log-file $AppLog}`"" -NoNewWindow -RedirectStandardOutput $ChocoLog     
            }
}

If ($Mode -eq "Uninstall")
{
    # Create log folder
    If (!(Test-Path $LogDir))
    {
        New-Item -Path $LogDir -ItemType Directory -Verbose
    }
        # Configure log filename 
        [string]$AppLogFile = $($PackageName+"-"+$(Get-Date -format MMddyyHHmmss)+"-"+"Uninstall"+".log")
        [string]$AppLog = "$($LogDir+"\"+$AppLogFile)"
        [string]$ChocoLogFile = $($PackageName+"-"+$(Get-Date -format MMddyyHHmmss)+"-"+"Choco-Uninstall"+".log")
        [string]$ChocoLog = "$($LogDir+"\"+$ChocoLogFile)"

        # Uninstall Chocolatey app pacakage
        Write-Host "Uninstalling Chocolatey package - $PackageName"
        Start-Process -Wait -FilePath "$env:SYSTEMROOT\system32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-Command `"& {choco uninstall $PackageName -y --log-file $AppLog}`"" -NoNewWindow -RedirectStandardOutput $ChocoLog
}