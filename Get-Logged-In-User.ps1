#=============================================================================# 
#                                                                             # 
# Get-Logged-In-User.ps1                                   		                # 
# Powershell Script to determine who is logged in.                            # 
# Author: James Kowalczik                                                     # 
# Creation Date: 04.15.2015                                                   # 
# Version: 1.0.0                                                              # 
#                                                                             # 
#=============================================================================# 

<#
    .Synopsis
     This will determine who is logged into a computer.
    .Example
     .\Get-Logged-In-User.ps1 -ComputerName acomputer
     This example will display who is logged into a computer named acomputer.
    .Example
    .\Get-Logged-In-User.ps1 -ComputerList acomputerlist.txt
     This example will display who is logged into all computers listed in a 
     file named acomputerlist.txt.  
     Note: 1 computer per line.
    .Description
     The Get-Logged-In-User cmdlet is used to list who is logged into a computer
     or list of computers.
    .Parameter ComputerName
     The value for this parameter can be a computer name or IP address. 
    .Parameter ComputerList
     The value for this parameter is a file name containing a list of computers
     or IP addresses.  1 item per line.
    .Notes
     Name:   Get-Logged-In-User
     Author: James Kowalczik
     Date:   04.08.2015
#>

Param(
   [String]$ComputerName = "localhost",
   [String]$ComputerListFile = "",
   [Bool]$Debug = $false
)

If($ComputerListFile.Length -gt 0){
   $ComputerList = Get-Content -Path $ComputerListFile # One system name per line
   foreach ($ComputerName in $ComputerList){
      ($ComputerName + ": " + @(Get-WmiObject -ComputerName $ComputerName -Namespace root\cimv2 -Class Win32_ComputerSystem)[0].UserName);
   }
}Else{
   Write-Host $ComputerName ":" @(Get-WmiObject -ComputerName $ComputerName -Namespace root\cimv2 -Class Win32_ComputerSystem)[0].UserName
}
