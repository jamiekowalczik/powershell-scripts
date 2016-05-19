#=============================================================================# 
#                                                                             # 
# Update-ComputerDescription.ps1                                       	      # 
# Powershell Script which updates a computer's description. 		      #
# Author: James Kowalczik                                                     # 
# Creation Date: 05.19.2016                                                   # 
# Version: 1.0.0							      #
#                                                                             # 
#=============================================================================# 

Param(
   [String]$Hostname = "localhost",
   [String]$Description = "",
   [String]$CSVFile = ""
)

If($CSVFile -eq ""){
   ### Run this if no CSV File is used.
   If($Description){
      Write-Host "Setting Description: $Description for Host: $Hostname"
      Try{
         $ret = Set-WmiInstance -Path "\\$Hostname\root\cimv2:Win32_OperatingSystem=@" -Arguments @{description=$Description} -ErrorAction Stop
      }Catch{ 
         Write-Host "Error Setting Description: $Description for Host: $Hostname" -ForegroundColor Red
      }
   }Else{
      Write-Host "You Must Specify a Description"
      Exit 1
   }
}Else{
   ### Run this is a CSV File is used. 
   Import-CSV $CSVFile | ForEach-Object {
      $Hostname = $_.Hostname
      $Description = $_.Description
      If($Hostname -And $Description){
         Write-Host "Setting Description: $Description for Host: $Hostname"
         Try{
            $ret = Set-WmiInstance -Path "\\$Hostname\root\cimv2:Win32_OperatingSystem=@" -Arguments @{description=$Description} -ErrorAction Stop
         }Catch{
            Write-Host "Error Setting Description: $Description for Host: $Hostname" -ForegroundColor Red
         }
      }Else{
         Write-Host "You Must Specify a Hostname and Description"
         Exit 1
      }
   }
}
