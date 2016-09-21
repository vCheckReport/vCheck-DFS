# Start of Settings
# End of Settings

# Find all member servers in DFS-R RG
$DFSMember = $script:RGs | Select-Object -ExpandProperty Members | Sort-Object -Unique

$DC = @()

foreach ($Server in $DFSMember)
{
   $DisabledConnection = Get-WmiObject -ComputerName $Server -Namespace "root\MicrosoftDFS" -Query "SELECT * FROM DfsrConnectionConfig" | Where {$_.Enabled -eq $false -and $_.Inbound -eq $false }

   [void]($DisabledConnection.ConnectionDn -match "CN=Topology,CN=(.*?),CN=DFSR-GlobalSettings,")
   $DC += $DisabledConnection | Select @{Name="SendingServer"; Expression={$Server}}, PartnerName, @{Name="ReplicationGroup";Expression={$Matches[1]}}
}
$DC

$Title = "List of disabled connections"
$Header =  "List of disabled connections"
$Comments = ("{0} connections are disabled" -f $DC.Count)
$Display = "Table"
$Author = "John Sneddon"
$PluginVersion = 1.0
$PluginCategory = "DFS"
