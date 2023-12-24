<#
If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
    }
    Catch {
        Throw "Failed to start $PSCOMMANDPATH"
    }
    Exit
}
#>
param (
        [string]$LanguageID,
        [string]$CompanyName
)

$argsString = ""
If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        foreach($k in $MyInvocation.BoundParameters.keys)
        {
            switch($MyInvocation.BoundParameters[$k].GetType().Name)
            {
                "SwitchParameter" {if($MyInvocation.BoundParameters[$k].IsPresent) { $argsString += "-$k " } }
                "String"          { $argsString += "-$k `"$($MyInvocation.BoundParameters[$k])`" " }
                "Int32"           { $argsString += "-$k $($MyInvocation.BoundParameters[$k]) " }
                "Boolean"         { $argsString += "-$k `$$($MyInvocation.BoundParameters[$k]) " }
            }
        }
        #Start-Process -FilePath "$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -ArgumentList "-File `"$($PSScriptRoot)\Install.ps1`" $($argsString)" -Wait -NoNewWindow
        Start-Process -FilePath "$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -ArgumentList "-File $PSCOMMANDPATH $($argsString)" -Wait -NoNewWindow
    }
    Catch {
        Throw "Failed to start 64-bit PowerShell"
    }
    Exit
}

function Install-LangPack
{

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
        If ($InstallLanguage -like $LanguageID)
        {
            Write-Host "Language Pack - $LanguageID is installed"
        }
        else {
            Write-Host "Something went wrong! Language Pack - $LanguageID is not installed"
            Exit 1
        }
            # Configure default language
            Set-SystemPreferredUILanguage -Language $LanguageID -Verbose

            Set-WinUILanguageOverride -Language $LanguageID -Verbose

            $OldList = Get-WinUserLanguageList
            $UserLanguageList = New-WinUserLanguageList -Language $LanguageID
            $UserLanguageList += $OldList | where { $_.LanguageTag -ne $LanguageID }
            $UserLanguageList | select LanguageTag
            Set-WinUserLanguageList -LanguageList $UserLanguageList -Force -Verbose
            
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
                else {
                    New-ItemProperty -Path $RegKey -Name $RegValue -Value $RegData -PropertyType "DWORD" -Verbose
                }
        
        Exit 3010
        Stop-Transcript
}

Install-LangPack -LanguageID $LanguageID -CompanyName $CompanyName