# Credit to T-Bone, for the $AccountMember variable - https://tbone.se/2023/10/24/how-to-use-windows-laps-to-secure-local-administrator-accounts/
$AccountName = "lapsadmin"
$AdminGroupSID  = "S-1-5-32-544"
$AdminGroupName = (Get-LocalGroup -SID $AdminGroupSID).Name
$AccountExist = (Get-LocalUser).Name -Contains $AccountName
$AccountMember  = if ($AccountName -in (([ADSI]"WinNT://./$AdminGroupName").psbase.Invoke('Members') | ForEach-Object {$_.GetType().InvokeMember("Name","GetProperty",$Null,$_,$Null)})){$true}else{$false}

# Create LAPS admin user account
If (!$AccountExist)
{
    Write-Host "The user $AccountName does not exist"
    Write-Host "Creating the user account now"
    $RandomPassword = ConvertTo-SecureString -String (-join ((33..126) | Get-Random -Count 32 | % {[char]$_})) -AsPlainText -Force
    New-LocalUser -Name $AccountName -Description "Custom local user account" -Password $RandomPassword
}

# Add the LAPS admin user account to the local administrators group
if (!$AccountMember)
{
    Write-Host "The user $AccountName is not a member of the local administrators group"
    Write-Host "Adding the user to the local administrators group now"
    Write-Host ""
    Add-LocalGroupMember -Name Administrators -Member $AccountName
}

# Detect user and group membership
$AccountExist = (Get-LocalUser).Name -Contains $AccountName
$AccountMember  = if ($AccountName -in (([ADSI]"WinNT://./$AdminGroupName").psbase.Invoke('Members') | ForEach-Object {$_.GetType().InvokeMember("Name","GetProperty",$Null,$_,$Null)})){$true}else{$false}

If ($AccountExist -and $AccountMember) 
{
    #Remediation Successful
    Write-Host "The user $AccountName is found and it is a member of the local administrators group"
    Exit 0
}  
else {
    #Remediation Failed
    Write-Host "The user $AccountName is not found or it is not a member of the local administrators group"
    Exit 1
}