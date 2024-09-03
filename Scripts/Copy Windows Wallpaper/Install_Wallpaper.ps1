<#
.SYNOPSIS
Script copies image files to a specified "theme" subdirectory within the Windows wallpaper directory. It can also remove the theme and its associated files if the 'Uninstall' parameter is used.

.DESCRIPTION
The script is designed to be deployed as a Win32 app using Microsoft Intune. It reads all image files from a "Wallpapers" subdirectory, 
which should be located in the same path as the script, and copies them to a new theme subdirectory within the Windows wallpaper directory.
If the 'Uninstall' switch is used, it removes the specified theme subdirectory and all its contents.

To package this script as a Win32 app, follow these steps:
1. Prepare with IntuneWinAppUtil.exe tool.
    - Place the script and the 'Wallpapers' folder in a directory.
    - Run IntuneWinAppUtil.exe and specify the source folder, the setup file (the script), and the output folder.
2. In Intune, add a new Win32 app and upload the generated .intunewin file.
3. Configure the install and uninstall commands for the app:
   - Install Command: powershell.exe -ExecutionPolicy Bypass -File "Copy-WallpaperToTheme.ps1" -theme "Nature"
   - Uninstall Command: powershell.exe -ExecutionPolicy Bypass -File "Copy-WallpaperToTheme.ps1" -theme "Nature" -Uninstall
6. For detection rules, use the 'Find path or file' option and configure as follows:
   - Rule type: Path
   - Path: %SystemRoot%\Web\Wallpaper\Nature
   - File or folder: (leave this blank to check for the folder's existence)
   - Detection method: File or folder exists
   - Associated with a 32-bit app on 64-bit clients: Unchecked

.PARAMETER theme
The name of the subdirectory within '%SystemRoot%\Web\Wallpaper' where the images will be copied to or removed from.

.PARAMETER Uninstall
Specifies whether the script should remove the theme subdirectory and its contents (also needs "theme" parameter)

.EXAMPLE
.\Copy-WallpaperToTheme.ps1 -theme "Nature"

This will copy all images from 'Wallpapers' to '%SystemRoot%\Web\Wallpaper\Nature' and set up the theme.

.EXAMPLE
.\Copy-WallpaperToTheme.ps1 -theme "Nature" -Uninstall

This will remove the 'Nature' theme subdirectory and all its contents from '%SystemRoot%\Web\Wallpaper'.

.NOTES
Please ensure that the "Wallpapers" subdirectory exists and contains image files.
The script requires administrative privileges to execute.

Last Modified: 2023-Nov-07

#>

# Requires -RunAsAdministrator

# Define parameters
param (
    [Parameter(Mandatory=$true)]
    [string]$theme,
    [switch]$Uninstall
)


# Tests for adminis priviliges 
function Test-AdminPrivileges {
    # Get the current Windows identity
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)

    # Check if the user is in the Administrators role
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "This script requires administrative privileges. Run it as an administrator."
    }
    else {
        Write-Host "Running with administrative privileges."
    }
}

# Example usage at the beginning of your script
try {
    Test-AdminPrivileges
    # The rest of your script goes here
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}


# Function to copy wallpapers to the theme directory
function Copy-WallpapersToTheme {
    param (
        [Parameter(Mandatory=$true)]
        [string]$theme
    )

    # Define the source and destination paths
    $sourcePath = Join-Path -Path $PSScriptRoot -ChildPath "Wallpapers"
    $destPath = Join-Path -Path $env:SystemRoot -ChildPath "Web\Wallpaper\$theme"

    # Check if the source directory exists
    if (-not (Test-Path -Path $sourcePath)) {
        Write-Error "Source directory '$sourcePath' does not exist."
        return
    }

    # Create the destination directory if it doesn't exist
    if (-not (Test-Path -Path $destPath)) {
        New-Item -Path $destPath -ItemType Directory | Out-Null
    }

    # Copy the image files to the destination directory
    try {
        Get-ChildItem -Path $sourcePath -Filter *.jpg | Copy-Item -Destination $destPath -Force
        Write-Host "Wallpapers copied to '$destPath'."
    }
    catch {
        Write-Error "An error occurred while copying the files: $_"
    }
}

# Function to remove wallpapers from the theme directory
function Remove-WallpapersFromTheme {
    param (
        [Parameter(Mandatory=$true)]
        [string]$theme
    )

    # Define the destination path
    $destPath = Join-Path -Path $env:SystemRoot -ChildPath "Web\Wallpaper\$theme"

    # Check if the destination directory exists
    if (Test-Path -Path $destPath) {
        # Remove the destination directory and all contents
        try {
            Remove-Item -Path $destPath -Recurse -Force
            Write-Host "Theme '$theme' and all associated wallpapers have been removed."
        }
        catch {
            Write-Error "An error occurred while removing the theme: $_"
        }
    }
    else {
        Write-Host "Theme '$theme' does not exist or has already been removed."
    }
}

# Main script execution
if ($Uninstall) {
    Remove-WallpapersFromTheme -theme $theme
} else {
    Copy-WallpapersToTheme -theme $theme
}

