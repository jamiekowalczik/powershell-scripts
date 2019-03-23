# invoke-nsxwebrequest -method "get" -uri "/api/4.0/edges/edge-7/dhcp/config" -connection $connection | % { $_.Content } | Format-XML
# invoke-nsxwebrequest -method "put" -uri "/api/4.0/edges/edge-7/dhcp/config" -body ([xml](get-content .\newpool.xml) | format-xml) -connection $connection | % { $_.Content } | Format-XML

$esg_name = "Edge01"
$esg_in_int_name = "edge-in-network1"
$esg_in_network_name = "network1"
$esg_in_int_index = 1
$esg_in_ipaddr = "192.168.14.254"
$esg_in_subnetmask = "24"
$esg_cluster = "Cluster1" #DRS must be enabled
$esg_datastore = "storage1"
$esg_username = "admin"
$esg_password = "VMware1VMware!"
$ippool1gw = "192.168.14.1"
$ippool1subnetmask = "255.255.255.0"
$ippool1suffix = "domain.local"
$ippool1dns1 = "192.168.14.1"
$ippool1dns2 = "8.8.8.8"
$ippool1leasetime = "60"
$ippool1Range = "192.168.14.11-192.168.14.15"
#Convert domain list to hex for option 119: .\Convert-DomainListToHex.ps1 "domain.local;domain2.local" 
#Convert string value to hex for option 15: https://codebeautify.org/string-hex-converter
$otherDHCPOptions = @{119 = "06646F6D61696E056C6F63616C0007646F6D61696E32056C6F63616C00"; 15 = "646f6d61696e2e6c6f63616c" }

### Requirement - source custom cmdlets - fixup and submit to VMware
. ./NsxDHCP.ps1
######

### Do the work ###
$esg_internalint_spec = New-NsxEdgeInterfaceSpec -Name $esg_in_int_name `
                     -Type Internal `
                     -ConnectedTo (Get-NsxLogicalSwitch $esg_in_network_name) `
                     -PrimaryAddress $esg_in_ipaddr `
                     -SubnetPrefixLength $esg_in_subnetmask -Index $esg_in_int_index

write-host -ForegroundColor cyan "Creating Edge Services Gateway:" $esg_name

$dhcp_esg = New-NsxEdge -Name $esg_name -Datastore (get-datastore $esg_datastore) `
            -Cluster (get-cluster $esg_cluster) -Username $esg_username `
            -Password $esg_password -FormFactor compact -AutoGenerateRules `
            -FwEnabled -FwDefaultPolicyAllow -EnableSSH -Interface $esg_internalint_spec

$DHCPPoolResults = Get-NsxEdge $esg_name | Get-NsxDHCPServer | Add-NsxDHCPPool -DefaultGateway $ippool1gw -DomainName $ippool1suffix -PrimaryNameServer $ippool1dns1 -SecondaryNameServer $ippool1dns2 -LeaseTime $ippool1leasetime -SubnetMask $ippool1subnetmask -IpRange $ippool1Range -OtherDHCPOptions $otherDHCPOptions -DebugMe true

$dhcp_esg = Get-NsxEdge $esg_name
$dhcp_esg.features.dhcp.enabled = "true"
$dhcp_esg | Set-NSXEdge -Confirm:$false
$dhcp_esg = Get-NsxEdge $esg_name
