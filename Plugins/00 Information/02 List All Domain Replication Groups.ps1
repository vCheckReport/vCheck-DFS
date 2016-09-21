# Start of Settings
# End of Settings

# Find domain root DN and search for DFSR config
$rootDN = ([ADSI]"LDAP://RootDSE").defaultNamingContext.ToString()
$RepGroups = ([adsi]"LDAP://CN=DFSR-GlobalSettings,CN=System,$rootDN").Children
$script:RGs = @()

# Loop over all replication groups to gather basic data
foreach ($rg in $RepGroups) 
{
   # replace special characters which break the ADSI query
   $RGDN = $rg.distinguishedName -replace "/", "\/"
   # Return the friendly name for each member server
   $members = ([ADSI]"LDAP://CN=Topology,$($RGDN)").children | 
                  select -expandproperty "msDFSR-ComputerReference" | 
                  % { [void]($_ -match "^CN=(.*?),"); $matches[1] } 

   $script:RGs += New-Object PSObject -Property @{ "Name"=$rg | Select -ExpandProperty Name;
                                                   "Description"=$rg | Select -ExpandProperty Description;
                                                   "Version" = $rg | Select -ExpandProperty "msDFSR-Version";
                                                   "Members" = $members;
                                                 }
}
# return a pretty table, but keep the original data intact
$script:RGs | Select Name, Description, Version, @{"Name"="Members"; "Expression"={($_.Members -join "<br />").Trim("<br />")}}

$Title = "List of Domain Replication Groups"
$Header =  "List of Domain Replication Groups"
$Comments = ("{0} Replication Groups in the {1} domain" -f $script:RGs.Count, $RootDN)
$Display = "Table"
$Author = "John Sneddon"
$PluginVersion = 1.0
$PluginCategory = "DFS"
