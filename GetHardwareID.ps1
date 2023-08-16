Connect-MgGraph -Scopes "Device.ReadWrite.All", "DeviceManagementManagedDevices.ReadWrite.All", "DeviceManagementServiceConfig.ReadWrite.All", "Domain.ReadWrite.All", "Group.ReadWrite.All", "GroupMember.ReadWrite.All", "User.Read"
$AutopilotProfile = Get-AutopilotProfile
$targetDirectory = "C:\temp"
$AutopilotProfile | ForEach-Object {
    New-Item -ItemType Directory -Path "$targetDirectory\$($_.displayName)"
    $_ | ConvertTo-AutopilotConfigurationJSON | Set-Content -Encoding Ascii "$targetDirectory\$($_.displayName)\AutopilotConfigurationFile.json"
}