#=============================================================================# 
#                                                                             # 
# Friday-After-Patch-Tuesday.ps1                                       	      # 
# Powershell Script to reboot servers to apply patches. 		      #
# Author: James Kowalczik                                                     # 
# Creation Date: 04.24.2015                                                   # 
# Version: 1.0.1							      #
# Modified: 05.29.2015							      #
#   -Add functionality to work with not domain computers.                     #  
#                                                                             # 
#=============================================================================# 

Param(
   [String]$Hostname = "localhost",
   [Bool]$Wait = $false,
   [String]$InstalledAfterDate = "",
   [String]$CSVFile = "",
   [Bool]$Restart = $false,
   [String]$Username = "",
   [String]$Password = "",
   [String]$EmailTo = "me@mail.com",
   [String]$EmailFrom = "Friday-After-Patch-Tuesday@mail.com",
   [String]$EmailSubject = "Friday After Patch Tuesday Maintenance",
   [String]$EmailServer = "mail.server.com",
   [Bool]$SendEmail = $true,
   [Bool]$Debug = $true
)

Import-Module .\Modules\Uptime.psm1
Import-Module .\Modules\Hotfixes.psm1
Import-Module .\Modules\Reboot.psm1

Function DoIt(){
   ## Get Uptime
   $Output += Get-Uptime -Hostname $Hostname -Username $Username -Password $Password -DebugMe $Debug | Out-String

   ## Get Recently Installed Updates
   $Output += Get-RecentHotfixes -Hostname $Hostname -Username $Username -Password $Password -InstalledAfterDate $InstalledAfterDate -DebugMe $Debug | Out-String

   ## Reboot Machine
   If($Restart){
      $Output += Restart-Machine -Hostname $Hostname -Username $Username -Password $Password -Wait $Wait -DebugMe $Debug | Out-String
   }

   Return $Output
}

$Output = ""
If($CSVFile -eq ""){
   ### Run this if no CSV File is used.  This will perform uptime/updates/reboot on 1 device #####
   If($InstalledAfterDAte -eq ""){ $InstalledAfterDate = [DateTime]::Today.AddDays(-1)}
   $Output = DoIt
}Else{
   ### Run this is a CSV File is used.  This will perform
   ### uptime/updates/reboot on all devices in the column
   ### with a header of 'Servers'.
   Import-CSV $CSVFile | ForEach-Object {
      If($_.Wait -ne "skip"){
         $Hostname = $_.Servers
         If($_.Username -ne ""){ $Username = $_.Username; $Password = $_.Password }Else{ $Username = ""; $Password = "" }
         If($_.Wait -eq "wait"){ $Wait = $true }Else{ $Wait = $false }
         If($InstalledAfterDAte -eq ""){ $InstalledAfterDate = [DateTime]::Today.AddDays(-14)}
         $Output += DoIt
      }Else{
         $Hostname = $_.Servers
         $Display = "Skipping $Hostname"
         If($Debug){Write-Host "$Display`n"}
         $Output += $Display
      }
   }
}

If($SendEmail -eq $true -And $Output -ne "" -And $EmailTo -ne "" -And $EmailSubject -ne "" -And $EmailServer -ne "" -And $EmailFrom -ne ""){
   Send-MailMessage -To $EmailTo -Subject $EmailSubject -Body $Output -SmtpServer $EmailServer -From $EmailFrom
}
