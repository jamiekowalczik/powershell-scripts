#=============================================================================# 
#                                                                             # 
# Hotfixes.psm1                                                   	      # 
# Powershell Script to get the uptime of a server. 			      #
# Author: James Kowalczik                                                     # 
# Creation Date: 07.24.2015                                                   # 
# Version: 1.0.0                                                              # 
#                                                                             # 
#=============================================================================# 

Function Get-RecentHotfixes {
   <#
    .Synopsis
     Lists all hotfixes installed after a specified date.  If not specified the default date is 1/1/1900.
    .Example
     Get-RecentHotfixes -Hostname aserver1 -Username "admin" -Password "mypassword" -InstalledAfterDate "7/24/2015" -DebugMe $false
     This example retrieves all hotfixes installed after 7/24/2015 on a server named aserver1. This examples uses alternate credentials to connect to the server and doesn't display any Debug output.
    .Description
     The Get-RecedntHotfixes cmdlet is used to retieves hotfixes installed on a server.  The return value for success is an array of hotfix information.
    .Parameter Hostname
     The value for this parameter can be an IP address or hostname for a computer to list recently installed hotfixes for.
    .Parameter Username
     The value for this parameter is the username to authenticate to the server.
    .Parameter Password
     The value for this parameter is the password to authenticate to the server.
    .Parameter InstalledAfterDate
     The value for this parameter can be a date.  Only hotfixes installed after this date are listed.
    .Parameter DebugMe
     The value for this parameter is either $true of $false.  If $true then Debug output is displayed to the console.
    .Outputs
     Hotfix details.
    .Notes
     Name:   Get-RecentHotfixes
     Module: Hotfixes.psm1
     Author: Jamie Kowalczik
     Date:   07.27.2015
  #>
   Param(
      [String]$Hostname = "localhost",
      [String]$InstalledAfterDate = "1/1/1900", ## Windows 2008 server (non R2) will not display the date.
      [Object]$Credentials,
      [String]$Username = "",
      [String]$Password = "",
      [Bool]$DebugMe = $false
   )
   
   Try{
      ## Allow some authentication
      If($Username -ne "" -And $Password -ne ""){
         $SecPassword = $Password | ConvertTo-SecureString -asPlainText -Force
         $creds = New-Object System.Management.Automation.PSCredential($Username,$SecPassword)
      }ElseIf($Credentials -ne $null){
         $creds = $Credentials
      }

      ## Get the data from the computer
      If($creds -ne $null){
         $Output = Get-HotFix -Computername $Hostname -Credential $creds | Where {$_.InstalledOn -gt $InstalledAfterDate} | ft -auto | Out-String
      }Else{
         $Output = Get-HotFix -Computername $Hostname | Where {$_.InstalledOn -gt $InstalledAfterDate} | ft -auto | Out-String
      }

      ## Output the results
      If($Output -eq ""){ $Output = $Hostname+": No Updates Installed Since "+$InstalledAfterDate }
      If($DebugMe){ Write-Host $Output }
      Return $Output
   }Catch{
      Write-Host $_.Exception.Message
      Write-Host $_.Exception.ItemName
   }
}

Function Get-RecentHotfixesFromList {
   Param(
      [String]$Hostname = "localhost",
      [Parameter(Mandatory=$True)][String]$CSVFile = "",
      [String]$EmailTo = "me@email.com",
      [String]$EmailFrom = "hotfix_report@email.com",
      [String]$EmailSubject = "Hotfix Report",
      [String]$EmailServer = "mail.server.com",
      [Bool]$SendEmail = $false,
      [Bool]$DebugMe
   )

   $Output = ""
   
   ### Run this if a CSV File is used.  This will check
   ### all devices in the column with a header of 'Servers'.
   Import-CSV $CSVFile | ForEach-Object {
      $MyArgs = @{}
      $MyArgs = @{ DebugMe=$DebugMe }
      $MyArgs += @{ Hostname=$_.Servers }
      If($_.Username -ne ""){ $MyArgs += @{ Username=$_.Username }; $MyArgs += @{ Password=$_.Password } }Else{ $MyArgs += @{ Username="" }; $MyArgs += @{ Password="" } }
      $Output += Get-RecentHotfixes @MyArgs | Out-String
   }

   If($SendEmail -eq $true -And $Output -ne "" -And $EmailTo -ne "" -And $EmailSubject -ne "" -And $EmailServer -ne "" -And $EmailFrom -ne ""){
      Send-MailMessage -To $EmailTo -Subject $EmailSubject -Body $Output -SmtpServer $EmailServer -From $EmailFrom
   }Else{
      Write-Host $Output
   }
}
