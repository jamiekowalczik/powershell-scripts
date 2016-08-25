Param(
   [String]$Computer = "localhost",
   [String]$CSVFile = "",
   [String]$Username = "",
   [String]$Password = "",
   [String]$EmailTo = "me@mail.here",
   [String]$EmailFrom = "CustomServices@mail.here",
   [String]$EmailSubject = "Custom Services",
   [String]$EmailServer = "mail.mail.here",
   [Bool]$SendEmail = $true
)

Function New-CustomItem(){
   Param($Computer, $ServiceName, $ServiceUser, $ErrorMessage)
   
   $aCustomItem = New-Object PSObject | Select-Object Computer,ServiceName,ServiceUser,ErrorMessage

   $aCustomItem.Computer = $Computer
   $aCustomItem.ServiceName = $ServiceName
   $aCustomItem.ServiceUser = $ServiceUser
   $aCustomItem.ErrorMessage = $ErrorMessage
  
   Return $aCustomItem   
}

Function Get-FilteredServiceResults(){
   ## Allow some authentication
   If($Username -ne "" -And $Password -ne ""){
      $SecPassword = $Password | ConvertTo-SecureString -asPlainText -Force
      $creds = New-Object System.Management.Automation.PSCredential($Username,$SecPassword)
   }ElseIf($Credentials -ne $null){
      $creds = $Credentials
   }
   
   $Results = ""
   Try{
      ## Get the data from the computer
      If($creds -ne $null){
         $Results = gwmi win32_service -computer $Computer -ErrorAction Stop  -Credential $creds | select * | Where { $_.StartName -NotLike "*NetworkService" -And $_.StartName -NotLike "*LocalSystem*" -And $_.StartName -NotLike "*LocalService*" }
      }Else{
         $Results = gwmi win32_service -computer $Computer -ErrorAction Stop | select * | Where { $_.StartName -NotLike "*NetworkService" -And $_.StartName -NotLike "*LocalSystem*" -And $_.StartName -NotLike "*LocalService*" }
      }
   }Catch{
      $aCustomItem = New-CustomItem -Computer $Computer -ServiceName "-" -ServiceUser "-" -ErrorMessage $_.Exception.Message
      Return $aCustomItem
   }
   ## Cut down on the output
   $Results = $Results | Select Name, StartName
   If($Results){
      $allItems = @()
      $Results | % {
         $allItems += New-CustomItem -Computer $Computer -ServiceName $_.Name -ServiceUser $_.StartName -ErrorMessage "-"
      }
      Return $allItems
   }Else{
      $aCustomItem = New-CustomItem -Computer $Computer -ServiceName "-" -ServiceUser "-" -ErrorMessage "-"
      Return $aCustomItem
   }
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

$Output = ""
If($CSVFile -eq ""){
   $fOutput = Get-FilteredServiceResults
   $Output = New-CustomItem -Computer $Computer -ServiceName $fOutput.ServiceName -ServiceUser $fOutput.ServiceUser -ErrorMessage $fOutput.ErrorMessage
   $Output = Get-HTMLGrid $Output
}Else{
   ### Run this is a CSV File is used. 
   $allItems = @()
   Import-CSV $CSVFile | ForEach-Object {
      $Computer = $_.Servers
      If($_.Username){ $Username = $_.Username; $Password = $_.Password }Else{ $Username = ""; $Password = "" }
      $fOutput = Get-FilteredServiceResults
      $allItems += New-CustomItem -Computer $Computer -ServiceName $fOutput.ServiceName -ServiceUser $fOutput.ServiceUser -ErrorMessage $fOutput.ErrorMessage
   }
   $Output = Get-HTMLGrid $allItems
}

If($SendEmail -eq $true -And $Output -ne "" -And $EmailTo -ne "" -And $EmailSubject -ne "" -And $EmailServer -ne "" -And $EmailFrom -ne ""){
   Send-MailMessage -To $EmailTo -Subject $EmailSubject -Body $Output -SmtpServer $EmailServer -From $EmailFrom -BodyAsHtml
}
