# Start of Settings
# Ignore connections with no backlog?
$IgnoreZero = $false
# End of Settings
$Backlog = @()

$DFSRStates = @("Uninitialized", "Initialized", "Initial Sync", "Auto Recovery", "Normal", "In Error")

# Find all member servers in DFS-R RG
$DFSMember = $script:RGs | Select-Object -ExpandProperty Members | Sort-Object -Unique

foreach ($Server in $DFSMember)
{
	Write-Host $server
	# Get all RGs the server is part of
	$RGroups = Get-WmiObject -ComputerName $Server -Namespace "root\MicrosoftDFS" -Query "SELECT * FROM DfsrReplicationGroupConfig"

	foreach ($Group in $RGroups)
	{
		Write-Host ("   {0}" -f $Group.ReplicationGroupName)
		# Get all replicated folders
		$DFSRGFoldersWMIQuery = ("SELECT * FROM DfsrReplicatedFolderConfig WHERE ReplicationGroupGUID='{0}'" -f $Group.ReplicationGroupGUID)
		$RGFolders = Get-WmiObject -ComputerName $Server -Namespace "root\MicrosoftDFS" -Query $DFSRGFoldersWMIQuery

		foreach ($Folder in $RGFolders)
		{
			# Get all connections
			$DFSRConnectionWMIQuery = ("SELECT * FROM DfsrConnectionConfig WHERE ReplicationGroupGUID='{0}'" -f $Group.ReplicationGroupGUID)
			$RGConnections = Get-WmiObject -ComputerName $Server -Namespace "root\MicrosoftDFS" -Query $DFSRConnectionWMIQuery
			
			foreach ($Connection in ($RGConnections | Where {-not $_.Inbound -and $_.Enabled }))
			{
				# Get the version vector - backlog counts need this to be accurate
				$WMIQuery = "SELECT * FROM DfsrReplicatedFolderInfo WHERE ReplicationGroupGUID = '" + $Group.ReplicationGroupGUID + "' AND ReplicatedFolderName = '" + $Folder.ReplicatedFolderName + "'" 
            $InboundPartnerWMI = Get-WmiObject -computername $Connection.PartnerName -Namespace "root\MicrosoftDFS" -Query $WMIQuery
				$Vv = $InboundPartnerWMI.GetVersionVector().VersionVector
				
				#Get the backlogcount from outbound partner 
				$WMIQuery = "SELECT * FROM DfsrReplicatedFolderInfo WHERE ReplicationGroupGUID = '" + $Group.ReplicationGroupGUID + "' AND ReplicatedFolderName = '" + $Folder.ReplicatedFolderName + "'" 
				$OutboundPartnerWMI = Get-WmiObject -computername $Server -Namespace "root\MicrosoftDFS" -Query $WMIQuery 
				$BacklogCount = $OutboundPartnerWMI.GetOutboundBacklogFileCount($Vv).BacklogFileCount   
				
				# Create object
				$backlog += New-Object PSObject -Property @{"Replication Group" = $Group.ReplicationGroupName;
																		  "Folder" = $Folder.ReplicatedFolderName;
																		  "State" = $DFSRStates[$OutboundPartnerWMI.State];
																		  "Sending Member" = $OutboundPartnerWMI.membername;
																		  "Receiving Member" = $InboundPartnerWMI.membername;
																		  "Backlog" = $BacklogCount;
														  }
			}
		}
	}
}
if ($$IgnoreZero)
{
	$Backlog = $Backlog | Where { $_.Backlog -gt 0}
}
$Backlog | Sort-Object "Replication Group", "Folder", "Sending Member", "Receiving Member" | Select "Replication Group", "Folder", "State", "Sending Member", "Receiving Member", "Backlog"

$Title = "List of backlogs for each replicated folder"
$Header =  "List of backlogs for each replicated folder"
$Comments = ("{0} replicated folders have backlogs" -f $Backlog.Count)
$Display = "Table"
$Author = "John Sneddon"
$PluginVersion = 1.0
$PluginCategory = "DFS"
