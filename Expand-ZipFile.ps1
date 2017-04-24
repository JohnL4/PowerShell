<#
.SYNOPSIS
Expand zipfile

.EXAMPLE
C:\PS> Expand-ZipFile -file foo.zip -destination c:\tmp\foo

.NOTES
From http://www.howtogeek.com/tips/how-to-extract-zip-files-using-powershell/

PowerShell Community Extensions (PSCX) has Expand-Archive, which is probably better.
#>

function Expand-ZipFile
{
   Param
   (
      [string]
      # The zip file to be expanded
      $file,

      [string]
      # The destination directory to receive expanded zipfile
      $destination
   )

   $shell = new-object -com shell.application
   $zip = $shell.NameSpace( $file)
   foreach ($item in $zip.items())
   {
      $shell.NameSpace( $destination).CopyHere( $item)
   }
}
