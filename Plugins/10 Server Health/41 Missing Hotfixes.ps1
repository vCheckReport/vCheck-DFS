# Start of Settings
# End of Settings

# See KB article for updated list: http://support.microsoft.com/kb/968429 and http://support.microsoft.com/kb/958802
$hotfixes = @{
					"2003" = @("KB2215778", "KB938666", "KB2462352", "KB979646", "KB967357", "KB953325", 
								  "KB954968", "KB953527", "KB933061", "KB919633", "KB912154", "KB908521");
					"2008" = @("KB2619531","KB2549311", "KB2387778", "KB2792165", "KB2525064", "KB962969");
					"2008 R2" = @("KB2639043", "KB2916267", "KB2916627", "KB2884176", 
									  "KB2663685","KB975763", "KB2851868", "KB979564", "KB2780453",
									  "KB978994", "KB967326");
					}
# Find all member servers in DFS-R RG
$DFSMember = $script:RGs | Select-Object -ExpandProperty Members | Sort-Object -Unique
# TODO: Also list Namespace servers!

$HotfixesMissing = @()

foreach ($Server in $DFSMember)
{
	# Find hotfixes installed
	$HotfixIDs = Get-Hotfix -computername $Server | Select -ExpandProperty HotfixID
	
	# Find OS version
	$version = Get-WmiObject -ComputerName $Server -class win32_operatingsystem | Select -expandProperty Version
	
	switch ($version.Substring(0,3)) 
	{
		"5.2" { $hf = $hotfixes["2003"]}    # 2003 R2
		"6.0" { $hf = $hotfixes["2008"]}    # 2008
		"6.1" { $hf = $hotfixes["2008 R2"]} # 2008 R2
	}
	
	foreach ($hotfix in $hf)
	{
		if ($HotfixIDs -notcontains $hotfix)
		{
			$HotfixesMissing += New-Object PSObject -Property @{"Server"=$Server; "Hotfix"=$hotfix}
		}
	}
}
$HotfixesMissing

$Title = "DFS servers missing hotfixes"
$Header =  "DFS servers missing hotfixes"
$Comments = ("{0} DFS hotfixes missing" -f $HotfixesMissing.Count)
$Display = "Table"
$Author = "John Sneddon"
$PluginVersion = 1.0
$PluginCategory = "DFS"
