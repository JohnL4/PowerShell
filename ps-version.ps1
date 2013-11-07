<#
   .SYNOPSIS
      Returns a string indicating the version of PowerShell it finds itself running in.
#>
function ps-version {
   if (Test-Path variable:psversiontable) {
      $versionPresent = $psversiontable.buildversion
      if (
         ($versionPresent.Major -ge 6) -and 
         ($versionPresent.Build -ge 6002) -and 
         ($versionPresent.Revision -ge 18111)
      ) {
         "V2 RTM"
      } else { 
         "V2 CTP Prerelease - Update to V2 RTM!"
      }
   } else {
      "V1 - Update to V2 RTM!"
   }
}
