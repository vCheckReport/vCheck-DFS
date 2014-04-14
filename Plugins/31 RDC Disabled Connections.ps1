# Start of Settings
# End of Settings

# Find all member servers in DFS-R RG
$DFSMember = $script:RGs | Select-Object -ExpandProperty Members | Sort-Object -Unique

$RDCDisabled = @()

foreach ($Server in $DFSMember)
{
	$DisabledConnection = Get-WmiObject -ComputerName $Server -Namespace "root\MicrosoftDFS" -Query "SELECT * FROM DfsrConnectionConfig" | Where {$_.RdcEnabled -eq $false -and $_.Enables -eq $true }
	
	[void]($DisabledConnection.ConnectionDn -match "CN=Topology,CN=(.*?),CN=DFSR-GlobalSettings,")
	$RDCDisabled += $DisabledConnection | Select @{Name="SendingServer"; Expression={$Server}}, PartnerName, @{Name="ReplicationGroup";Expression={$Matches[1]}}
}

$Title = "List of connections with Remote Differential Compression (RDC) disabled"
$Header =  "List of connections with RDC disabled"
$Comments = ("{0} connections are disabled" -f $RDCDisabled.Count)
$Display = "Table"
$Author = "John Sneddon"
$PluginVersion = 1.0
$PluginCategory = "DFS"
