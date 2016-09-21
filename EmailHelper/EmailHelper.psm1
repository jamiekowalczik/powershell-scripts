Function Set-AlternatingRows {
   <#
      .SYNOPSIS
         Simple function to alternate the row colors in an HTML table
      .DESCRIPTION
	 This function accepts pipeline input from ConvertTo-HTML or any
	 string with HTML in it.  It will then search for <tr> and replace 
	 it with <tr class=(something)>.  With the combination of CSS it
	 can set alternating colors on table rows.
		
 	 CSS requirements:
	 .odd  { background-color:#ffffff; }
	 .even { background-color:#dddddd; }
		
	 Classnames can be anything and are configurable when executing the
	 function.  Colors can, of course, be set to your preference.
		
	 This function does not add CSS to your report, so you must provide
	 the style sheet, typically part of the ConvertTo-HTML cmdlet using
	 the -Head parameter.
      .PARAMETER Line
	 String containing the HTML line, typically piped in through the
	 pipeline.
      .PARAMETER CSSEvenClass
	 Define which CSS class is your "even" row and color.
      .PARAMETER CSSOddClass
	 Define which CSS class is your "odd" row and color.
      .EXAMPLE $Report | ConvertTo-HTML -Head $Header | Set-AlternateRows -CSSEvenClass even -CSSOddClass odd | Out-File HTMLReport.html
	
      $Header can be defined with a here-string as:
      $Header = @"
         <style>
	 TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
	 TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
	 TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
	 .odd  { background-color:#ffffff; }
	 .even { background-color:#dddddd; }
	 </style>
      "@
		
	 This will produce a table with alternating white and grey rows.  Custom CSS
	 is defined in the $Header string and included with the table thanks to the -Head
	 parameter in ConvertTo-HTML.
      .NOTES
         Author:         Martin Pugh
	 Twitter:        @thesurlyadm1n
	 Spiceworks:     Martin9700
	 Blog:           www.thesurlyadmin.com
		
	 Changelog:
	    1.1         Modified replace to include the <td> tag, as it was changing the class
                        for the TH row as well.
            1.0         Initial function release
      .LINK
         http://community.spiceworks.com/scripts/show/1745-set-alternatingrows-function-modify-your-html-table-to-have-alternating-row-colors
      .LINK
         http://thesurlyadmin.com/2013/01/21/how-to-create-html-reports/
   #>
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory,ValueFromPipeline)][string]$Line,
      [Parameter(Mandatory)][string]$CSSEvenClass,
      [Parameter(Mandatory)][string]$CSSOddClass
   )
   Begin {
      $ClassName = $CSSEvenClass
   }
   Process {
      If ($Line.Contains("<tr><td>")){	
         $Line = $Line.Replace("<tr>","<tr class=""$ClassName"">")
         If ($ClassName -eq $CSSEvenClass){	
            $ClassName = $CSSOddClass
         }Else{	
            $ClassName = $CSSEvenClass
         }
      }
      Return $Line
   }
}

Function Get-HTMLGrid(){
   [CmdletBinding()]
   Param(
      $ArrayOfData,
      [String]$TableHeaderBackgroundColor = "#446600",
      [String]$TableHeaderFontColor = "white",
      [String]$EvenBackgroundColor = "#ffffff",
      [String]$OddBackgroundColor = "#eeffcc"
   )
   $aGrid = ""
   ## http://exchangeserverpro.com/powershell-html-email-formatting/
$style = @"
      <style>BODY{font-family: Arial; font-size: 10pt;}
         TABLE{border: 1px solid black; border-collapse: collapse;}
         TH{border: 1px solid black; background: $TableHeaderBackgroundColor; padding: 5px; color: $TableHeaderFontColor;}
         TD{border: 1px solid black; padding: 5px; }
         .odd{background-color:$EvenBackgroundColor;}
         .even{background-color:$OddBackgroundColor;}
      </style>
"@
   
   $aGrid = $ArrayOfData | ConvertTo-Html -Head $style
   $aGrid = $aGrid | Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd | Out-String
   Return $aGrid
}

Function Send-EmailMessage(){
   Param(
      [String]$EmailTo = "me@here.com",
      [String]$EmailFrom = "EVItems@here.com",
      [String]$EmailSubject = "EV Items",
      [String]$EmailServer = "mail.here.com",
      [Int]$EmailPort = 0,
      [Bool]$EmailUseSSL = $false,
      [Bool]$EmailBodyAsHtml = $true,
      [String]$EmailUsername = "",
      [String]$EmailPassword = "",
      [Bool]$SendEmail = $true,
      [String]$Body
   )
   If($SendEmail -eq $true -And $Body -ne $null -And $EmailTo -ne "" -And $EmailSubject -ne "" -And $EmailServer -ne "" -And $EmailFrom -ne ""){
      If($Body -ne ""){ $SplatVars += @{Body = $Body} }
      If($EmailTo -ne ""){ $SplatVars += @{To = $EmailTo} }
      If($EmailSubject -ne ""){ $SplatVars += @{Subject = $EmailSubject} }
      If($EmailServer -ne ""){ $SplatVars += @{SmtpServer = $EmailServer} }
      If($EmailFrom -ne ""){ $SplatVars += @{From = $EmailFrom} }
      If($EmailBodyAsHTML -eq $true){ $SplatVars += @{BodyAsHtml = $true} }
      If($EmailUseSSL -eq $true){ $SplatVars += @{UseSSL = $true} }
      If($EmailPort -ne 0){ $SplatVars += @{Port = $EmailPort} }
      If($EmailUsername -ne "" -And $EmailPassword -ne ""){
         $SecPassword = $EmailPassword | ConvertTo-SecureString -asPlainText -Force
         $creds = New-Object System.Management.Automation.PSCredential($EmailUsername,$SecPassword)
         $SplatVars += @{Credential = $creds}
      }
      Send-MailMessage @SplatVars
   }
}
