<#PSScriptInfo
.SYNOPSIS
    Script to create a scheduled task
 
.DESCRIPTION
    This script will create a scheduled task which executes at user logon. The scheduled task is configured with the local "Users" group security principal.
    The scheduled task is configured using a json file.

.PARAMETER ConfigFile
    Path to the json file. This parameter is mandatory and the script will fail to run, if not configured

.PARAMETER TaskStatus
    Can be either be "Register" to register (create) the scheduled task or "Unregister" (remove) the scheduled task

.PARAMETER LogDir
    Log file folder. Default is $env:ProgramData\ScheduledTask

.PARAMETER LogFile
    $Logfile name. Default is ScheduledTask-$(Get-Date -Format ddMMyyHHmmss).log
        
.EXAMPLE
    .\ScheduledTaskUser.ps1 -ConfigFile ScheduledTaskConfig.json -TaskStatus Register
        Register (create) a shceduled task, based on the information provided in the ConfigFile

    .\ScheduledTaskUser.ps1 -ConfigFile ScheduledTaskConfig.json -TaskStatus Unregister
        Unregister (remove) a shceduled task, based on the information provided in the ConfigFile

.NOTES

To do:
Support for multiple json files
        
.AUTHOR
    Kasper Johansen 
    https://kasperjohansen.net

.COPYRIGHT
    Feel free to use this as much as you want :)

.RELEASENOTES
    22-01-25 - 1.0.0 - Release to public

.CHANGELOG
    22-01-2024 - 1.0.0 - Release to public

#>

param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigFile,
        [Parameter(Mandatory = $true)][ValidateSet("Register","Unregister")]
        [string]$TaskStatus,
        [Parameter(Mandatory = $false)]
        [string]$LogDir = "$env:ProgramData\ScheduledTask",
        [Parameter(Mandatory = $false)]
        [string]$LogFile = "ScheduledTask-$(Get-Date -Format ddMMyyHHmmss).log"
)

# Function to write log file
# Credit goes to Sean McAvinue for this write log function - https://seanmcavinue.net/2024/08/07/a-simple-and-effective-powershell-log-function/
Function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Message,
        [Parameter(Mandatory = $true)]
        [String]$LogFilePath,
        [Parameter(Mandatory = $true)]
        [String]$LogType,
        [Parameter(Mandatory = $false)]
        [switch]$DebugEnabled = $false
    )
    $Date = Get-Date
    $Message = "$Date - [$LogType] $Message"
    Add-Content -Path $LogFilePath -Value $Message
    if ($DebugEnabled) {
        If ($LogType -eq "Error") {
            write-host $Message -ForegroundColor Red
        }
        elseif ($LogType -eq "Warning") {
            write-host $Message -ForegroundColor Yellow
        }
        else {
            write-host $Message
        }
    }
}

# Create $LogDir folder if it does not exist
If (!(Test-Path "$LogDir"))
{        
    New-Item -Path "$LogDir" -ItemType Directory -ErrorAction Continue
    Write-Log -Message "Creating folder: $LogDir" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)    
}    

# Check if config file exists
If (Test-Path -Path $ConfigFile -PathType Leaf)
{
    try {
        Write-Log -Message "Loading configuration: $ConfigFile" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
        $Config = Get-Content -Path $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
        Write-Log -Message "Configuration file loaded: $ConfigFile" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
    }
    catch {
        Write-Log -Message "Unable to load configuration file: $ConfigFile" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile)
        Write-Log -Message "Error: $_" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
        Exit 1
    }
}
else {
    Write-Log -Message "Cannot find configuration file: $ConfigFile" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile)
    Write-Log -Message "Script exiting" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
    Exit 1
}

# Read configuration file
[string]$TaskName = $Config.ScheduledtaskInfo.Taskname
[string]$TaskDescription = $Config.ScheduledtaskInfo.Taskdescription
[string]$TaskPath = $Config.ScheduledtaskInfo.Taskpath
[string]$TaskAction = $Config.ScheduledtaskInfo.TaskAction
[string]$TaskActionArguments = $Config.ScheduledtaskInfo.TaskActionArguments
[string]$TaskActionWorkingDirectory = $Config.ScheduledtaskInfo.TaskActionWorkingDirectory
[string]$TaskTrigger = $Config.ScheduledtaskInfo.TaskTrigger

#Region register scheduled task
If ($TaskStatus -eq "Register")
{
# Find Builtin\Users name on localized Windows
# Well known SIDs are found here - https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers#well-known-sids
$GroupName = Get-LocalGroup -SID "S-1-5-32-545"

# Define additional variables containing scheduled task action, principal, trigger and settings
$A = New-ScheduledTaskAction -Execute $TaskAction -Argument $TaskActionArguments -WorkingDirectory $TaskActionWorkingDirectory
$P = New-ScheduledTaskPrincipal -GroupId $GroupName -RunLevel Limited
$S = New-ScheduledTaskSettingsSet -Compatibility Win8 -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries -DontStopOnIdleEnd
$T = New-ScheduledTaskTrigger -AtLogon

# Cook it all up and create the scheduled task
$RegSchTaskParameters = @{
    TaskName    = $TaskName
    Description = $TaskDescription
    TaskPath    = $TaskPath
    Action      = $A
    Principal   = $P
    Settings    = $S
    Trigger     = $T
}

try {
    Write-Log -Message "Registering scheduled task: $TaskName" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
    Write-Log -Message "Scheduled task description: $TaskDescription" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
    Write-Log -Message "Scheduled task path: $TaskPath" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
    Write-Log -Message "Scheduled task principal: $GroupName" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
    Write-Log -Message "Scheduled task action: $TaskAction" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
    Write-Log -Message "Scheduled task action arguments: $TaskActionArguments" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
    Write-Log -Message "Scheduled task working directory: $TaskActionWorkingDirectory" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
    Write-Log -Message "Scheduled task trigger: $TaskTrigger" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
    Register-ScheduledTask @RegSchTaskParameters -ErrorAction Stop   
}
catch {
    Write-Log -Message "Failed to register scheduled task: $TaskName" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile)
    Write-Log -Message "Error: $_" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile) 
    Exit 1
}
#EndRegion Scheduled Task parameters

#Region create Intune detection file
If (Get-ScheduledTask -TaskName $TaskName)
{
    try {
        Write-Log -Message "Create tag file: $($Taskname+"Tag"+".tag") in $Logdir" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
        Set-Content -Path "$LogDir\$($Taskname+"Tag"+".tag")" -Value "$Taskname has been created successfully"    
    }
    catch {
        Write-Log -Message "Failed to create tag file: $($Taskname+"Tag"+".tag") - Error: $_" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile)
        Exit 1
    }
}
else {
    Write-Log -Message "Scheduled task: $TaskName is not found" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile)
    Exit 1
}
#EndRegion create Intune detection file
}

#Region unregister scheduled task
If ($TaskStatus -eq "Unregister")
{
    try {
        Write-Log -Message "Unregistering scheduled task: $TaskName" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
        Write-Log -Message "Scheduled task path: $TaskPath" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
        Unregister-ScheduledTask -TaskName $TaskName -TaskPath $($TaskPath + "\") -Confirm:$false -ErrorAction Stop
    }
    catch {
        Write-Log -Message "Failed to unregister scheduled task: $TaskName" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile)
        Write-Log -Message "Error: $_" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile) 
        Exit 1
    }

    If (Test-Path -Path "$LogDir\$($Taskname+"Tag"+".tag")" -ErrorAction Continue)
    {
        try {
            Write-Log -Message "Removing tag file: $($Taskname+"Tag"+".tag") in $LogDir" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
            Remove-Item -Path "$LogDir\$($Taskname+"Tag"+".tag")"
        }
        catch {
            Write-Log -Message "Unable to remove tag file: $($Taskname+"Tag"+".tag") in $LogDir - Error: $_" -LogType "Error" -LogFilePath $($LogDir+"\"+$LogFile)
            Exit 1
        }        
    }
    else {
        Write-Log -Message "Tag file does not exist: $($Taskname+"Tag"+".tag") in $LogDir" -LogType "Info" -LogFilePath $($LogDir+"\"+$LogFile)
    }
}