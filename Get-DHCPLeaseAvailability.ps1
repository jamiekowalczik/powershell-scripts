#====================================================#
#                                                    #
# Get-DHCPLeaseAvailability.ps1                      #
# Powershell script to send an email alert if the    #
# lease availability for a particular scope is       #
# nearly full with the ability to exclude certain    #
# scopes.                                            #
#                                                    #
# Author: James Kowalczik                            #
# Creation Date: 06.29.2016                          #
# Version 1.0.0                                      #
#                                                    #
#====================================================#
Param(
   [String]$EmailTo = "kowalczjm@herkimer.edu",
   [String]$EmailFrom = "DHCP_Scope_Alert@herkimer.edu",
   [String]$EmailServer = "mail.herkimer.edu",
   [String[]]$ExcludeScopes = "172.16.45.0",
   [String]$msgONo = "Running out of addresses for scope",
   [String]$DHCPServer = "dc2",
   [Int]$ScopeThreshold = 95,
   [Bool]$SendEmail = $true,
   [Bool]$Debug = $false
)

Import-Module DhcpServer
$Alert = Get-DhcpServerv4ScopeStatistics -ComputerName $DHCPServer | Where-Object -FilterScript { $_.PercentageInUse -gt $ScopeThreshold } | Where { $ExcludeScopes -NotContains $_.ScopeId }
If($Alert){ 
   [String]$ScopeId = $Alert.ScopeId
   $ScopeInUse = $Alert.InUse
   $ScopeFree = $Alert.Free 
   If($SendEmail){
      Send-MailMessage -To $EmailTo -Subject "Alert $msgONo" -Body "ALERT - $msgONo $ScopeId `nIn Use: $ScopeInUse `nFree: $ScopeFree" -SmtpServer $EmailServer -From $EmailFrom
   }
   If($Debug){ Write-Host $msgONo $ScopeId `nIn Use: $ScopeInUse `nFree: $ScopeFree }
}
