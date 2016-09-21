[CmdletBinding()]
Param(
   [Bool]$SearchDC = $false,
   [String]$Computer = "",
   [String]$Log = "",
   [String]$Data = "",
   [Int]$SpanOfHours = 0,
   [Int]$ID = 0,
   [Bool]$Debug = $false
)

Import-Module .\EmailHelper\EmailHelper.psm1

######################
######################
Function New-CustomItem(){
   Param($TimeCreated, $Id, $ProviderName, $Message)
   
   $aCustomItem = New-Object PSObject | Select-Object TimeCreated,Id,ProviderName,Message

   $aCustomItem.TimeCreated = $TimeCreated
   $aCustomItem.Id = $Id
   $aCustomItem.ProviderName = $ProviderName
   $aCustomItem.Message = $Message
  
   Return $aCustomItem   
}

Function Get-EVItems() {
   Try{
      If($SearchDC){ $Computer = (Get-AdDomain).PDCEmulator }

      If($Log.Length -gt 0){
         $SplatVars += @{LogName = $Log}
      }
      If($ID -ne 0){
         $SplatVars += @{ID = $ID}
      }
      If($Data.Length -gt 0){
         $SplatVars += @{Data = $Data}
      }
      If($SpanOfHours -gt 0){
         $StartTime = (Get-Date).AddHours(-$SpanOfHours)
         $SplatVars += @{StartTime = $StartTime}
      }
      
      $Events = Get-WinEvent -Computername $Computer -FilterHashtable $SplatVars -ErrorAction Stop

      $allItems = @()
      ForEach($aEvent in $Events){
         $allItems += New-CustomItem -TimeCreated $aEvent.TimeCreated -Id $aEvent.Id -ProviderName $aEvent.ProviderName -Message $aEvent.Message
      }
      $Output = Get-HTMLGrid -ArrayOfData $allItems

      Return $Output
   }Catch{
      Write-Host $_.Exception.Message
      Write-Host $_.Exception.ItemName
   }
}
######################
######################
$Output = Get-EVItems

If($Debug){ $Output }
If($Output -ne ""){Send-EmailMessage -Body $Output}
