# Script parameters
Param(
    [string]$Executable = "CitrixWorkspaceApp.exe",
    [string]$InstallParameters = "/silent /noreboot /includeSSON ENABLE_SSON=YES",
    [string]$UninstallParameters = "/uninstall /noreboot /silent",
    [switch]$Install,
    [switch]$Uninstall
    )

function Install-Application ($Executable, $InstallParameters, $UninstallParameters, $Install, $Uninstall)
{
# Get script dir
$ScriptDir = (Get-Location).Path
Push-Location $ScriptDir

# Install application
If ($Install)
{
    Start-Process -Wait $Executable -ArgumentList "$InstallParameters" -WindowStyle Minimized
}
        # Uninstall application
        If ($Uninstall)
        {
            Start-Process -Wait $Executable -ArgumentList "$UninstallParameters" -WindowStyle Minimized
        }
}

Install-Application $Executable $InstallParameters $UninstallParameters $Install $Uninstall