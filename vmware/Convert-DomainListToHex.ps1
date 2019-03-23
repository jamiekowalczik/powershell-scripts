Param(
   [String]$DomainList
)

Function ConvertCharToHexString{
   Param(
      [String]$val
   )
   $ret = [System.BitConverter]::ToString([System.Text.Encoding]::UTF8.GetBytes($val))
   Return $ret
}

Function ConvertIntToHexString{
   Param(
      [Int]$val
   )
   $ret = '{0:X2}' -f $val
   Return $ret
}

Function ConvertDomainListToHexString{
   Param(
      [String]$val
   )
   $splittedDomainSearchList = $val -split "\;"
   $domainSearchListHexArray = @()

   Foreach ($domain in $splittedDomainSearchList) {
      $splittedDomainParts = $domain -split "\."
      Foreach ($domainPart in $splittedDomainParts){
         $domainSearchListHexArray += ConvertIntToHexString($domainPart.Length)
         $domainPartHexArray = $domainPart.ToCharArray()
         Foreach ($item in $domainPartHexArray){
            $domainSearchListHexArray += ConvertCharToHexString($item)
         }
      }
      $domainSearchListHexArray += ConvertIntToHexString("0")
   }
   Return $domainSearchListHexArray -join ''
}

ConvertDomainListToHexString $DomainList
