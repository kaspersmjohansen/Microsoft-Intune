# Detect DisplayName value in application uninstall key
$RegDetect             = "False"

# Detect version value in Displayname
$RegValueVersionDetect = "False" # equal #equalgreater

# Detect file
$FileDetect            = "False"

# Detect file version 
$FileVersionDetect     = "" # equal #equalgreater

# Detect AppX application
$AppXDetect             = "true"

# Folder to detect file
$ProgramPath = ""

# File to be detected
$ProgramFile = ""

# File version
$ProgramFileVersion = ""

# Application uninstall registry key
$ProgramRegKey = ""

# Application version registry value
$ProgramRegVersion = ""

# Appx application name to be detected
$AppXName = "MSteams"

# Specific file exists
If ($FileDetect -eq "True")
{
    If (Test-Path -Path "$ProgramPath\$ProgramFile")
    {
        Write-Host "Found it!"
    }
}

# Specific file with version equal to exists
If ($FileVersionDetect -eq "equal")
{
    $ProgramFileVersionCurrent = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$ProgramPath\$ProgramFile").FileVersion
    If($ProgramFileVersionCurrent -eq $ProgramFileVersion)
    {
        Write-Host "Found it!"
    }
}

# Specific file with version equal to or greater exists
If ($FileVersionDetect -eq "equalgreater")
{
    $ProgramFileVersionCurrent = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$ProgramPath\$ProgramFile").FileVersion
    If($ProgramFileVersionCurrent -ge $ProgramFileVersion)
    {
        Write-Host "Found it!"
    }
}

# DisplayName exists in $ProgramRegKey
If ($RegDetect -eq "True")
{
    If ($ProgramRegValue -eq "True")
    {
        $RegContent = Get-ItemProperty -Path $ProgramRegKey
        If($RegContent.DisplayName)
        {
            Write-Host "Found it!"
        }
    }
}

# DisplayVersion equal to $ProgramRegVersion
If ($RegValueVersionDetect -eq "equal")
{
    $RegContent = Get-ItemProperty -Path $ProgramRegKey
    If($RegContent.DisplayVersion -eq $ProgramRegVersion)
    {
        Write-Host "Found it!"
    }
}

# DisplayVersion equal to or greater than $ProgramRegVersion
If ($RegValueVersionDetect -eq "equalgreater")
{
    $RegContent = Get-ItemProperty -Path $ProgramRegKey
    If($RegContent.DisplayVersion -ge $ProgramRegVersion)
    {
        Write-Host "Found it!"
    }
}

# Detect if AppX application is installed
If ($AppXDetect -eq "true")
{
    If (Get-AppxPackage -Name $AppXName -AllUsers -ErrorAction SilentlyContinue)
    {
        Write-Host "Found it!"
    }
}