# Credit to T-Bone, for the $AccountMember variable - https://tbone.se/2023/10/24/how-to-use-windows-laps-to-secure-local-administrator-accounts/
$AccountName = ""
$AdminGroupSID  = "S-1-5-32-544"
$AdminGroupName = (Get-LocalGroup -SID $AdminGroupSID).Name
$AccountExist = (Get-LocalUser).Name -Contains $AccountName
$AccountMember  = if ($AccountName -in (([ADSI]"WinNT://./$AdminGroupName").psbase.Invoke('Members') | ForEach-Object {$_.GetType().InvokeMember("Name","GetProperty",$Null,$_,$Null)})){$true}else{$false}

# Detect user and group membership
If ($AccountExist -and $AccountMember) 
{
    Write-Host "The user $AccountName is found and it is a member of the local administrators group"
    Exit 0
}
elseif ($AccountExist -and !$AccountMember){
    Write-Host "The user $AccountName is found but it is not a member of the local administrators group"
    Exit 1
}
else {
    Write-Host "The user $AccountName is not found"
    Exit 1
}