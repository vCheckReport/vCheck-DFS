# Start of Settings
# How many days do you want to go back in the event logs?
$EventLogDays = 1
# What type of events do you want to report?
$EventLogTypes = "Error"
# End of Settings

# Find all member servers in DFS-R RG
$DFSMember = $script:RGs | Select-Object -ExpandProperty Members | Sort-Object -Unique

$Services = @("DFS", "DFSR")

$issues = @()

foreach ($Server in $DFSMember)
{
   # Start with the basics, can you ping the server
   if (-not (Test-connection -ComputerName $Server -Count 1 -Quiet))
   {
      $issues += New-Object PSObject -Property @{"Server" = $Server; "Issue"="Server is not pingable"; "Level" = "Critical"}
   }

   # Check DFS Services are running
   $ServiceStatus = Get-Service -ComputerName $Server | Where { ($Services -contains $_.Name) -and $_.Status -ne "Running"}
   foreach ($svc in $ServiceStatus)
   {
      $issues += New-Object PSObject -Property @{"Server" = $Server; "Issue"=("Service is not running: {0}" -f $svc.DisplayName); "Level" = "Critical"}
   }
   # Check WMI Namespace
   try 
   {
      $WMI = Get-WmiObject -ComputerName $Server -Namespace "root\MicrosoftDFS" -List
      
      if (!$WMI) 
      {
         $issues += New-Object PSObject -Property @{"Server" = $Server; "Issue"="WMI Namespace not valid"; "Level" = "Critical"}
      }
   }
   catch
   {
      $issues += New-Object PSObject -Property @{"Server" = $Server; "Issue"="WMI Namespace not valid"; "Level" = "Critical"}
   }

   # Eventlogs
    $Events = @(Get-EventLog -LogName "DFS Replication" -ComputerName $Server -EntryType $EventLogTypes -After (Get-Date).AddDays(-$EventLogDays) -ErrorAction SilentlyContinue)
    if ($Events.Count -gt 0)
    {
        foreach ($event in $Events)
        {
            $issues += New-Object PSObject -Property @{"Server" = $Server; "Issue"=$Event.Message; "Level" = $Event.EntryType}
        }
    }
}

$issues 

$Title = "Health issues for DFS Member servers"
$Header =  "Health issues for DFS Member servers"
$Comments = ""
$Display = "Table"
$Author = "John Sneddon"
$PluginVersion = 1.0
$PluginCategory = "DFS"