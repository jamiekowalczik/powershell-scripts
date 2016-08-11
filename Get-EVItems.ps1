Function Get-EVItems() {
   [CmdletBinding()]
   Param(
      [String]$ComputerName = "",
      [String]$Log = "Security",
      [String]$Data = "10.10.10.10",
      [Int]$SpanOfHours = 6,
      [Int]$ID = 4625
   )
   $StartTime = (Get-Date).AddHours(-$SpanOfHours)
   Try{
      ## Find the domain controller PDCe role
      If($ComputerName.Length -gt 0){
         $Pdce = $ComputerName
      }Else{
         $Pdce = (Get-AdDomain).PDCEmulator
      }

      If($Data.Length -gt 0){
         $Events = Get-WinEvent -Computername $Pdce -FilterHashtable @{LogName = "$Log"; Data = "$Data"; StartTime = $StartTime}
      }Else{
         $Events = Get-WinEvent -Computername $Pdce -FilterHashtable @{LogName = "$Log"; StartTime = $StartTime}
      }

      Return $Events
   }Catch{
      Write-Host $_.Exception.Message
      Write-Host $_.Exception.ItemName
   }
}

Function New-UsefulEVItem(){
   Param($Computer, $TimeCreated, $Data, $AllData)
   
   $aEVItem = New-Object PSObject | Select-Object Computer,TimeCreated,Data,AllData

   $aEVItem.Computer = $Computer
   $aEVItem.TimeCreated = $TimeCreated
   $aEVItem.Data = $Data
   $aEVItem.AllData = $AllData
  
   Return $aEVItem   
}

Function Normalize-EVData(){
   [CmdletBinding()]
   Param(
      [Object]$Data
   )
   
   $allItems = @()
   $events | % {
      $arrMessage = $_.Message -Split '[\r\n]'

      $aLineOfUsefulData = $arrMessage | Where-Object { $_ -iLike "*Account Name*" -And $_ -iNotLike "*$ComputerName*" }
      $aUsername = $aLineOfUsefulData -Split '\s+'
      $aUsername = $aUsername[3]

      $aLineOfUsefulData = $arrMessage | Where-Object { $_ -iLike "*Network Address*" }
      $ip = $aLineOfUsefulData -Split '\s+'
      $ipaddr = $ip[4]
      If($ipaddr.Length -eq 0){
         $ipaddr = $ip[3]
      }
      If($ipaddr.Length -eq 0){
        $ipaddr = "none"
      }
      $allItems += New-UsefulEVItem $ipaddr $_.TimeCreated $aUsername $_.Message
   }
   Return $allItems  
}

$ComputerName = "dc.local"
$Data = "10.10.10.10"

$events = Get-EVItems -ComputerName $ComputerName -Data $Data

$nEvents = Normalize-EVData -Data $events

Return $nEvents

#$UniqueItems = $allItems| Sort-Object Computer -Unique
#Return $UniqueItems
