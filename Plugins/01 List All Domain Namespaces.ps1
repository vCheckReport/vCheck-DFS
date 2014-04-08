# Start of Settings
# End of Settings
 
$rootDN = ([ADSI]"LDAP://RootDSE").defaultNamingContext.ToString()
 
$NS = ([adsi]"LDAP://CN=Dfs-Configuration,CN=System,$rootDN").Children
$script:Namespaces = @()

foreach ($n in $NS) 
{ 
	$script:Namespaces += New-Object PSObject -Property @{ "Name"=$n | Select -ExpandProperty Name;
														 "Servers" = ($n.remoteServerName -join "<br />") -replace "<br />\*", ""
														}
}
$script:Namespaces

$Title = "List of Domain Namespaces"
$Header =  "List of Domain Namespaces"
$Comments =("{0} namespaces in the {1} domain" -f $script:Namespaces.Count, $RootDN)
$Display = "Table"
$Author = "John Sneddon"
$PluginVersion = 1.0
$PluginCategory = "DFS"