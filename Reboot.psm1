#=============================================================================# 
#                                                                             # 
# Reboot.psm1                                                   	      # 
# Powershell Script to get the uptime of a server. 			      #
# Author: James Kowalczik                                                     # 
# Creation Date: 07.24.2015                                                   # 
# Version: 1.0.0                                                              # 
#                                                                             # 
#=============================================================================# 

Function Restart-Machine {
   Param(
      [String]$Hostname = "localhost",
      [Bool]$Wait = $false,
      [String]$Username = "",
      [String]$Password = "",
      [Object]$Credentials,
      [Bool]$DebugMe = $false
   )
   
   ## Allow some authentication
   If($Username -ne "" -And $Password -ne ""){
      $SecPassword = $Password | ConvertTo-SecureString -asPlainText -Force
      $creds = New-Object System.Management.Automation.PSCredential($Username,$SecPassword)
   }ElseIf($Credentials -ne $null){
      $creds = $Credentials
   }

   $Now = Get-Date
   If($Wait){
      $Output = "Rebooting and waiting for $Hostname at $Now"
      If($DebugMe){ Write-Host $Output }

      If($creds -ne $null){
         Restart-Computer -Force -ComputerName $Hostname -Wait -For WMI -Credential $creds
      }Else{
         Restart-Computer -Force -ComputerName $Hostname -Wait -For WMI
      }
      Return $Output
   }Else{
      $Output = "Rebooting and NOT waiting for $Hostname at $Now"
      If($DebugMe){ Write-Host $Output }
      
      If($creds -ne $null){
         Restart-Computer -Force -ComputerName $Hostname -Credential $creds
      }Else{
         Restart-Computer -Force -ComputerName $Hostname
      }
      Return $Output
   }
}

Function Restart-MachinesFromList {
   Param(
      [String]$Hostname = "localhost",
      [Parameter(Mandatory=$True)][String]$CSVFile = "",
      [String]$EmailTo = "me@mail.com",
      [String]$EmailFrom = "reboot_report@mail.com",
      [String]$EmailSubject = "Reboot Report",
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
      If($_.Wait -eq "wait"){ $MyArgs += @{ Wait=$true } }Else{ $MyArgs += @{ Wait=$false } }
      $Output += Reboot-Machine @MyArgs | Out-String
   }

   If($SendEmail -eq $true -And $Output -ne "" -And $EmailTo -ne "" -And $EmailSubject -ne "" -And $EmailServer -ne "" -And $EmailFrom -ne ""){
      Send-MailMessage -To $EmailTo -Subject $EmailSubject -Body $Output -SmtpServer $EmailServer -From $EmailFrom
   }Else{
      Write-Host $Output
   }
}
