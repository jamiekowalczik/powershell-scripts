#=============================================================================# 
#                                                                             # 
# Friday-After-Patch-Tuesday.ps1                                       	      # 
# Powershell Script to reboot servers to apply patches. 		      #
# Author: James Kowalczik                                                     # 
# Creation Date: 04.24.2015                                                   # 
# Version: 1.0.0                                                              # 
#                                                                             # 
#=============================================================================# 

Param(
   [String]$Hostname = "localhost",
   [Bool]$Wait = $false,
   [String]$InstalledAfterDate = "",
   [String]$CSVFile = "",
   [Bool]$Restart = $false,
   [String]$EmailTo = "alert@me.here",
   [String]$EmailFrom = "Friday-After-Patch-Tuesday@me.here",
   [String]$EmailSubject = "Friday After Patch Tuesday Maintenance",
   [String]$EmailServer = "mail.me.here",
   [Bool]$SendEmail = $false,
   [Bool]$Debug = $true
)

Function Get-Uptime {
   $os = Get-WmiObject win32_operatingsystem -ComputerName $Hostname -ErrorAction SilentlyContinue
   If($os -eq $null){
      $Display = "Can't connect to: $Hostname"
      If($Debug){ Write-Host $Display}
      Return $Display
   }Else{
      $uptime = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))
      $Now = Get-Date
      $Display = "Server: " + $Hostname + " - Current Time: " + $Now + " - Uptime: " + $Uptime.Days + " days, " + $Uptime.Hours + " hours, " + $Uptime.Minutes + " minutes" 
      If($Debug){ Write-Host $Display }
      Return $Display
   }
}

Function Get-Recent-Hotfixes {
   $Display = Get-HotFix -Computername $Hostname | Where {$_.InstalledOn -gt $InstalledAfterDate} | Out-String
   If($Debug){ Write-Host $Display }
   Return $Display
}

Function Reboot-Windows() {
   If($Restart){
      $Now = Get-Date
      If($Wait){
         $Display = "Rebooting and waiting for $Hostname at $Now"
         If($Debug){ Write-Host $Display }
         #Restart-Computer -Force -ComputerName $Hostname -Wait -For WIM
         Return $Display
      }Else{
         $Display = "Rebooting and NOT waiting for $Hostname at $Now"
         If($Debug){ Write-Host $Display }
         #Restart-Computer -Force -ComputerName $Hostname
         Return $Display
      }
   }
}

Function DoIt(){
   ## Get Uptime
   $Output += Get-Uptime | Out-String

   ## Get Recently Installed Updates
   $Output += Get-Recent-Hotfixes | Out-String

   ## Reboot Machine
   $Output += Reboot-Windows | Out-String
   
   Return $Output
}

$Output = ""
If($CSVFile -eq ""){
   ### Run this if no CSV File is used.  This will check 1 device #####
   If($InstalledAfterDAte -eq ""){ $InstalledAfterDate = [DateTime]::Today.AddDays(-1)}
   $Output = DoIt
}Else{
   ### Run this is a CSV File is used.  This will check
   ### all devices in the column with a header of 'Servers'.
   Import-CSV $CSVFile | ForEach-Object {
      $Hostname = $_.Servers
      If($_.Wait -eq "wait"){ $Wait = $true }Else{ $Wait = $false }
      If($InstalledAfterDAte -eq ""){ $InstalledAfterDate = [DateTime]::Today.AddDays(-1)}
      $Output += DoIt
   }
}

If($SendEmail){
   Send-MailMessage -To $EmailTo -Subject $EmailSubject -Body $Output -SmtpServer $EmailServer -From $EmailFrom
}
