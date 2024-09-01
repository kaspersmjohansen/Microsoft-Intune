# Detect if DisplayName registry value exist in application uninstall registry key
$RegDetect             = "False" # True or False

# Detect DisplayName value version in application uninstall registry key
$RegValueVersionDetect = "" # equal or equalgreater

# Detect if application filename exist in application folder
$FileDetect            = "False" # True or False

# Detect application filename version in application folder
$FileVersionDetect     = "" # equal or equalgreater

# Application folder
$ProgramPath = ""

# Application filename
$ProgramFile = ""

# Application filename version
$ProgramFileVersion = ""

# Application uninstall registry key
$ProgramRegKey = ""

# Application registry value version
$ProgramRegVersion = ""

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