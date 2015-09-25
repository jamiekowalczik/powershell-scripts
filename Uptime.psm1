#=============================================================================# 
#                                                                             # 
# Uptime.psm1                                                   	      # 
# Powershell Script to get the uptime of a server. 			      #
# Author: James Kowalczik                                                     # 
# Creation Date: 07.24.2015                                                   # 
# Version: 1.0.0                                                              # 
#                                                                             # 
#=============================================================================# 

Function Get-Uptime {
   Param(
      [String]$Hostname = "localhost",
      [String]$Username,
      [String]$Password,
      [Object]$Credentials,
      [Bool]$DebugMe=$false
   )

   ## Allow some authentication
   If($Username -ne "" -And $Password -ne ""){
      $SecPassword = $Password | ConvertTo-SecureString -asPlainText -Force
      $creds = New-Object System.Management.Automation.PSCredential($Username,$SecPassword)
   }ElseIf($Credentials -ne $null){
      $creds = $Credentials
   }
   
   ## Get the data from the computer
   If($creds -ne $null){
      $os = Get-WmiObject win32_operatingsystem -ComputerName $Hostname -ErrorAction SilentlyContinue -Credential $creds
   }Else{
      $os = Get-WmiObject win32_operatingsystem -ComputerName $Hostname -ErrorAction SilentlyContinue
   }

   ## Output the results
   If($os -eq $null){
      $Output = "Can't connect to: $Hostname"
      If($DebugMe){ Write-Host $Output}
      Return $Output
   }Else{
      $uptime = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))
      $Now = Get-Date
      $Output = "Server: " + $Hostname + " - Current Time: " + $Now + " - Uptime: " + $Uptime.Days + " days, " + $Uptime.Hours + " hours, " + $Uptime.Minutes + " minutes" 
      If($DebugMe){ Write-Host $Output }
      Return $Output
   }
}

Function Get-UptimeFromList {
   Param(
      [String]$Hostname = "localhost",
      [Parameter(Mandatory=$True)][String]$CSVFile = "",
      [String]$EmailTo = "me@mail.com",
      [String]$EmailFrom = "uptime_report@mail.com",
      [String]$EmailSubject = "Uptime Report",
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
      $Output += Get-Uptime @MyArgs | Out-String
   }

   If($SendEmail -eq $true -And $Output -ne "" -And $EmailTo -ne "" -And $EmailSubject -ne "" -And $EmailServer -ne "" -And $EmailFrom -ne ""){
      Send-MailMessage -To $EmailTo -Subject $EmailSubject -Body $Output -SmtpServer $EmailServer -From $EmailFrom
   }Else{
      Write-Host $Output
   }
}
