[CmdletBinding()]
Param(
   [String]$Log = "Security",
   [String]$Data = "user1",
   [Int]$SpanOfHours = 36,
   [Int]$ID = 4625,
   [String]$EmailTo = "me@here.com",
   [String]$EmailFrom = "EVItems@here.com",
   [String]$EmailSubject = "EV Items",
   [String]$EmailServer = "mail.here.com",
   [Bool]$SendEmail = $true
)

######################
######################
Function Get-EVItems() {
   Try{
      ## Find the domain controller PDCe role
      $Pdce = (Get-AdDomain).PDCEmulator

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
      
      $Events = Get-WinEvent -Computername $Pdce -FilterHashtable $SplatVars -ErrorAction Stop

      $allItems = @()
      ForEach($aEvent in $Events){
         $allItems += New-CustomItem -TimeCreated $aEvent.TimeCreated -Id $aEvent.Id -ProviderName $aEvent.ProviderName -Message $aEvent.Message
      }
      $Output = Get-HTMLGrid $allItems

      Return $Output
   }Catch{
      Write-Host $_.Exception.Message
      Write-Host $_.Exception.ItemName
   }
}

Function New-CustomItem(){
   Param($TimeCreated, $Id, $ProviderName, $Message)
   
   $aCustomItem = New-Object PSObject | Select-Object TimeCreated,Id,ProviderName,Message

   $aCustomItem.TimeCreated = $TimeCreated
   $aCustomItem.Id = $Id
   $aCustomItem.ProviderName = $ProviderName
   $aCustomItem.Message = $Message
  
   Return $aCustomItem   
}

Function Get-HTMLGrid($aArrayOfData){
   #Write-Host $aArrayOfData
   $aGrid = ""
   ## http://exchangeserverpro.com/powershell-html-email-formatting/
   $style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
   $style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
   $style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
   $style = $style + "TD{border: 1px solid black; padding: 5px; }"
   $style = $style + "</style>"
   
   $aGrid = $aArrayOfData | ConvertTo-Html -Head $style | Out-String
   Return $aGrid
}
######################
######################
$Output = Get-EVItems

If($SendEmail -eq $true -And $Output -ne $null -And $EmailTo -ne "" -And $EmailSubject -ne "" -And $EmailServer -ne "" -And $EmailFrom -ne ""){
   Send-MailMessage -To $EmailTo -Subject $EmailSubject -Body $Output -SmtpServer $EmailServer -From $EmailFrom -BodyAsHtml
}
