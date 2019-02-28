Function ValidateEdge {

    Param (
        [Parameter (Mandatory=$true)]
        [object]$argument
    )

    #Check if we are an XML element
    if ($argument -is [System.Xml.XmlElement] ) {
        if ( $argument | get-member -name edgeSummary -memberType Properties) {
            if ( -not ( $argument.edgeSummary | get-member -name objectId -Membertype Properties)) {
                throw "XML Element specified does not contain an edgesummary.objectId property.  Specify an NSX Edge Services Gateway object"
            }
            if ( -not ( $argument.edgeSummary | get-member -name objectTypeName -Membertype Properties)) {
                throw "XML Element specified does not contain an edgesummary.ObjectTypeName property.  Specify an NSX Edge Services Gateway object"
            }
            if ( -not ( $argument.edgeSummary | get-member -name name -Membertype Properties)) {
                throw "XML Element specified does not contain an edgesummary.name property.  Specify an NSX Edge Services Gateway object"
            }
            if ( -not ( $argument | get-member -name type -Membertype Properties)) {
                throw "XML Element specified does not contain a type property.  Specify an NSX Edge Services Gateway object"
            }
            if ($argument.edgeSummary.objectTypeName -ne "Edge" ) {
                throw "Specified value is not a supported type.  Specify an NSX Edge Services Gateway object."
            }
            if ($argument.type -ne "gatewayServices" ) {
                throw "Specified value is not a supported type.  Specify an NSX Edge Services Gateway object."
            }
            $true
        }
        else {
            throw "Specify a valid Edge Services Gateway Object"
        }
    }
    else {
        throw "Specify a valid Edge Services Gateway Object"
    }
}

Function ValidateDHCPServer {

    Param (
        [Parameter (Mandatory=$true)]
        [object]$argument
    )

    #Check if it looks like a DHCP Server element
    if ($argument -is [System.Xml.XmlElement] ) {

        #if ( -not ( $argument | get-member -name edgeId -Membertype Properties)) {
        #    throw "XML Element specified does not contain an edgeId property."
        #}
        $true
    }
    else {
        throw "Specify a valid DHCP Server object."
    }
}

Function Get-NsxDHCPServer {

    <#
    .SYNOPSIS
    Retrieves the DHCP Server configuration from a specified Edge.

    .DESCRIPTION
    An NSX Edge Service Gateway provides all NSX Edge services such as firewall,
    NAT, DHCP, VPN, load balancing, and high availability.

    The NSX DHCP Server...

    This cmdlet retrieves the DHCP Server configuration from a specified Edge.
    .EXAMPLE

    PS C:\> Get-NsxEdge Edge01 | Get-NsxDHCPServer

    #>

    [CmdLetBinding(DefaultParameterSetName="Name")]

    param (
        [Parameter (Mandatory=$true,ValueFromPipeline=$true,Position=1)]
            [ValidateScript({ ValidateEdge $_ })]
            [System.Xml.XmlElement]$Edge
    )

    begin {}

    process {

        #We append the Edge-id to the associated DHCP Server XML to enable pipeline workflows and
        #consistent readable output (PSCustom object approach results in 'edge and
        #DHCP Server' props of the output which is not pretty for the user)

        $_DHCPServer = $Edge.features.dhcp.CloneNode($True)
        Add-XmlElement -xmlRoot $_DHCPServer -xmlElementName "edgeId" -xmlElementText $Edge.Id
        $_DHCPServer

    }
}

# $DHCPPoolResults = Get-NsxEdge Edge01 | Get-NsxDHCPServer | Add-NsxDHCPPool -AutoConfigureDNS "false" -DefaultGateway "192.168.14.1" -DomainName "kowalczik.hopto.org" -PrimaryNameServer "192.168.2.1" -SecondaryNameServer "8.8.8.8" -LeaseTime "60" -SubnetMask "255.255.255.0" -IpRange "192.168.14.5-192.168.14.7" -AllowHugeRange "false"
Function Add-NsxDHCPPool {

    <#
    .SYNOPSIS
    Adds a new DHCP Server Pool to the specified ESG.

    .DESCRIPTION
    An NSX Edge Service Gateway provides all NSX Edge services such as firewall,
    NAT, DHCP, VPN, load balancing, and high availability.

    The NSX DHCP Server...

    This cmdlet creates a new DHCP Server pool.

    .EXAMPLE
    Example1: Need to create member specs for each of the pool members first

    PS C:\> $DHCPPoolResults = Get-NsxEdge Edge01 | Get-NsxDHCPServer |
        New-NsxDHCPPool -AutoConfigureDNS "false" -DefaultGateway "192.168.14.1" -DomainName "domain.local" 
       -PrimaryNameServer "192.168.14.1" -SecondaryNameServer "8.8.8.8" -LeaseTime "60" 
       -SubnetMask "255.255.255.0" -IpRange "192.168.14.5-192.168.14.7" -AllowHugeRange "false"

    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidDefaultValueSwitchParameter","")] # Cant remove without breaking backward compatibility
    param (

        [Parameter (Mandatory=$true,ValueFromPipeline=$true,Position=1)]
            [ValidateScript({ ValidateDHCPServer $_ })]
            [System.Xml.XmlElement]$DHCPServer,
        [Parameter (Mandatory=$False)]
            [ValidateNotNullorEmpty()]
            [String]$AutoConfigureDNS="false",
        [Parameter (Mandatory=$False)]
            [ValidateNotNullOrEmpty()]
            [IpAddress]$DefaultGateway="",
        [Parameter (Mandatory=$False)]
            [ValidateNotNullOrEmpty()]
            [String]$DomainName="",
        [Parameter (Mandatory=$False)]
            [ValidateNotNullOrEmpty()]
            [IpAddress]$PrimaryNameServer="",
        [Parameter (Mandatory=$False)]
            [ValidateNotNullOrEmpty()]
            [IpAddress]$SecondaryNameServer="",
        [Parameter (Mandatory=$False)]
            [ValidateNotNullOrEmpty()]
            [Int]$LeaseTime=86400,
        [Parameter (Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [String]$SubnetMask,
        [Parameter (Mandatory=$True)]
            [ValidateNotNullOrEmpty()]
            [String]$IpRange,
        [Parameter (Mandatory=$False)]
            [ValidateNotNullorEmpty()]
            [String]$AllowHugeRange="false",
        [Parameter (Mandatory=$False)]
            #PowerNSX Connection object
            [ValidateNotNullOrEmpty()]
            [PSCustomObject]$Connection=$defaultNSXConnection
    )

    begin {
    }

    process {

        #Clone the node to avoid modifying the original
        $_DHCPServer = $DHCPServer.CloneNode($true)
        $edgeId = $_DHCPServer.edgeId
        $_DHCPServer.RemoveChild( $((Invoke-XPathQuery -QueryMethod SelectSingleNode -Node $_DHCPServer -Query 'descendant::edgeId')) ) | out-null
        $IPPools = Invoke-XPathQuery -QueryMethod SelectSingleNode -Node $_DHCPServer -Query 'descendant::ipPools'

        [System.XML.XMLElement]$xmlDHCPPool = $IPPools.OwnerDocument.CreateElement("ipPool")
        $IPPools.appendChild($xmlDHCPPool) | out-null

        Add-XmlElement -xmlRoot $xmlDHCPPool -xmlElementName "autoConfigureDNS" -xmlElementText $AutoConfigureDNS
        Add-XmlElement -xmlRoot $xmlDHCPPool -xmlElementName "defaultGateway" -xmlElementText $DefaultGateway
        Add-XmlElement -xmlRoot $xmlDHCPPool -xmlElementName "domainName" -xmlElementText $DomainName
        Add-XmlElement -xmlRoot $xmlDHCPPool -xmlElementName "primaryNameServer" -xmlElementText $PrimaryNameServer
        Add-XmlElement -xmlRoot $xmlDHCPPool -xmlElementName "secondaryNameServer" -xmlElementText $SecondaryNameServer
        Add-XmlElement -xmlRoot $xmlDHCPPool -xmlElementName "leaseTime" -xmlElementText $LeaseTime
        Add-XmlElement -xmlRoot $xmlDHCPPool -xmlElementName "subnetMask" -xmlElementText $SubnetMask
        Add-XmlElement -xmlRoot $xmlDHCPPool -xmlElementName "ipRange" -xmlElementText $IpRange
        Add-XmlElement -xmlRoot $xmlDHCPPool -xmlElementName "allowHugeRange" -xmlElementText $AllowHugeRange

        $URI = "/api/4.0/edges/$($EdgeId)/dhcp/config"
        $body = $_DHCPServer.OuterXml

        Write-Output $URI
        Write-Output $body

        Write-Progress -activity "Update Edge Services Gateway $EdgeId" -status "DHCP Server Config"
        $null = invoke-nsxwebrequest -method "put" -uri $URI -body $body -connection $connection
        write-progress -activity "Update Edge Services Gateway $EdgeId" -completed

        $UpdatedDHCPServer = Get-NsxEdge -objectId $EdgeId -connection $connection | Get-NsxDHCPServer
        $UpdatedDHCPServer
    }

    end {}
}
