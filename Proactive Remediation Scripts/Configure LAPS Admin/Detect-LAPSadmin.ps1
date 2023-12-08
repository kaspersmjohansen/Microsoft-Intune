# Detect new
$AccountName = "lapsadmin"
$AccountExist = (Get-LocalUser).Name -Contains $AccountName
$AccountMember = (Get-LocalGroupMember -Name "Administrators").Name -Contains "$env:COMPUTERNAME\$AccountName"

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