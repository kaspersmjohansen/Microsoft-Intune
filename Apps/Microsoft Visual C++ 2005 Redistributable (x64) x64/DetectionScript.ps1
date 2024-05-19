# Detect DisplayName value in application uninstall key
$RegDetect             = "False"

# Detect version value in Displayname
$RegValueVersionDetect = "equalgreater" # equal #equalgreater

# Detect file
$FileDetect            = "False"

# Detect file version 
$FileVersionDetect     = "equalgreater" # equal #equalgreater

# Folder to detect file
$ProgramPath = ""

# File to be detected
$ProgramFile = ""

# File version
$ProgramFileVersion = ""

# Application uninstall registry key
$ProgramRegKey = "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{ad8a2fa1-06e7-4b0d-927d-6e54b3d31028}"

# Application version registry value
$ProgramRegVersion = "8.0.61000"

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