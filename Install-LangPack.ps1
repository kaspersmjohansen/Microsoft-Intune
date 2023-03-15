function Install-LangPack
{
        param(
             $LanguageID,
             $CompanyName
        )
        # Configure log file and log file path
        $LogFile = "Install-LangPack-$LanguageID.log"
        $LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
        If (!(Test-Path -Path $LogPath))
        {
            New-Item -Path $LogPath -ItemType Directory
        }
        Start-Transcript -Path "$LogPath\$LogFile" | Out-Null
        
        # Install language pack
        Install-Language -Language $LanguageID -Verbose

        # Check if language pack has installed correctly, otherwise throw an "Exit 1"
        $InstallLanguage = (Get-InstalledLanguage).LanguageId
        If ($installedLanguage -like $LanguageID)
        {
            Write-Host "Language Pack - $LanguageID is installed"
            Exit 0

        }
        else {
            Write-Host "Something went wrong! Language Pack - $LanguageID is not installed"
            Exit 1
        }
        
        # Create registry key and value to detect if language pack is installed
        $RegKey = "HKLM:Software\$CompanyName\Intune\LanguagePacks"
        $RegValue = "LanguagePack-$LanguageID"
        $RegData = "1"        

        If (!(Test-Path -Path $RegKey))
        {
            New-Item -Path "HKLM:Software\$CompanyName" -Verbose
            New-Item -Path "HKLM:Software\$CompanyName\Intune" -Verbose
            New-Item -Path "HKLM:Software\$CompanyName\Intune\LanguagePacks" -Verbose

            New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "DWORD" -Verbose
        }
        
        Exit 0
        Stop-Transcript

}

Install-LangPack -LangaugeID $LanguageID