[CmdletBinding()]
Param(
   [String]$SearchBase = "CN=Users,DC=contoso,DC=com",
   [String]$EmailDomain = "CONTOSO.COM",
   [Bool]$ReportOnly = $true
)

Add-Type -TypeDefinition @"
   public struct OurUser {
   public string Username;
   public string PrimarySMTPAddress;
   public string NewPrimarySMTPAddress;
   public override string ToString() { return Username; }
}
"@

Function Get-UsersWithIncorrectPrimarySMTPAddress{
   $AllADUsers = Get-ADUser -Filter * -Property memberOf,Enabled -SearchBase $SearchBase -SearchScope OneLevel

   $OurUsers = @()
   ForEach($aUser in $AllADUsers){
      $FixPrimarySMTPAddress = $true
      $aUserDN = $aUser.DistinguishedName
      $aUsername = $aUser.sAMAccountName
      $user = Get-ADUser -Properties homedirectory,extensionAttribute8,LegacyExchangeDN,Mail,MailNickName,proxyAddresses,TextEncodedORAddress,userPrincipalName,DisplayName,DistinguishedName -Filter {DistinguishedName -eq $aUserDN}
   
      $PrimarySMTPAddress = ""
      ForEach($aProxyAddress in $user.ProxyAddresses){ 
         If($aProxyAddress -Like "SMTP:$aUsername@$EmailDomain"){ 
            $FixPrimarySMTPAddress = $false
         }
         If($aProxyAddress.StartsWith("SMTP:")){
            $PrimarySMTPAddress = $aProxyAddress
         }
      }
   
      If($FixPrimarySMTPAddress){
         $Username = $user.sAMAccountName
         $aNewProxyAddress = "SMTP:$Username@$EmailDomain"
         $newUser = New-Object OurUser
         $newUser.Username = $user.sAMAccountName
         $newUser.PrimarySMTPAddress = $PrimarySMTPAddress
         $newUser.NewPrimarySMTPAddress = $aNewProxyAddress
         $OurUsers += $newUser
    
         If(-Not $ReportOnly){
            Set-ADUser $user -Remove @{proxyaddresses=$PrimarySMTPAddress}
            Set-ADUser $user -Add @{proxyaddresses=$aNewProxyAddress}
         }
      }
   }
   Return $OurUsers
}

Get-UsersWithIncorrectPrimarySMTPAddress
