# Start of Settings
# End of Settings

# Find all member servers in DFS-R RG
$DFSRMember = $script:RGs | Select-Object -ExpandProperty Members | Sort-Object -Unique

$Backlog = @()
$i = 0

foreach ($Server in $DFSRMember)
{
   $i++
   # Get all RGs the server is part of
   $RGroups = Get-WmiObject -ComputerName $Server -Namespace "root\MicrosoftDFS" -Query "SELECT * FROM DfsrReplicationGroupConfig"

   foreach ($Group in $RGroups)
   {
      Write-Progress -Activity "Checking Replication group backlog" -Status ("{0}: {1}" -f $Server, $Group.ReplicationGroupName) -PercentComplete (($i/$DFSRMember.Count)*100)
      # Get all replicated folders

      $DFSRConnectionWMIQuery = "SELECT * FROM DfsrConnectionConfig WHERE ReplicationGroupGUID='" + $Group.ReplicationGroupGUID + "'"
      $RGConnections = Get-WmiObject -Computername $Server -Namespace "root\MicrosoftDFS" -Query $DFSRConnectionWMIQuery | Where {$_.Enabled}
      
      foreach ($Connection in $RGConnections)
      {
         $DFSRGFoldersWMIQuery = ("SELECT * FROM DfsrReplicatedFolderConfig WHERE ReplicationGroupGUID='{0}'" -f $Group.ReplicationGroupGUID)
         $RGFolders = Get-WmiObject -ComputerName $Server -Namespace "root\MicrosoftDFS" -Query $DFSRGFoldersWMIQuery

         if ($connection.Inbound)
         {
            $Smem = $Connection.PartnerName
            $Rmem = $Server
         }
         else
         {
            $Smem = $Server
            $Rmem = $Connection.PartnerName
         }
         
         foreach ($Folder in $RGFolders)
         {
            $BLCommand = ("dfsrdiag Backlog /RGName:'{0}' /RFName:'{1}' /SendingMember:'{2}' /ReceivingMember:'{3}'" -f $Group.ReplicationGroupName, $Folder.ReplicatedFolderName, $Smem, $Rmem)

            $Backlog = Invoke-Expression -Command $BLCommand


                if (($Backlog -match "[0-9]+\. (.*)$").count -gt 0)
                {
                    foreach ($BL in $Backlog)
                    {
                        if ($BL -match "[0-9]+\. (.*)$")
                        {
                            New-Object PSObject -Property @{"Sending Member"= $Smem; 
                                                            "Receiving Member"= $Rmem;
                                                            "Folder" = $Folder.ReplicatedFolderName; 
                                                            "Item" = $Matches[1]; } | 
                                Select "Sending Member", "Receiving Member", "Folder", "Item"
                        }
                    }
                }
         }
      }
   }
}
Write-Progress -Activity "Checking Replication group backlog" -Status "Complete" -Completed

$Title = "List of backlogs for each replicated folder"
$Header =  "List of backlogs for each replicated folder"
$Comments = ("{0} replicated folders have backlogs. Only top 100 are show for each folder." -f $Backlog.Count)
$Display = "Table"
$Author = "John Sneddon"
$PluginVersion = 1.0
$PluginCategory = "DFS"
