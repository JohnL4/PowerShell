<#
.SYNOPSIS
   Modify path to include Ruby binaries
.EXAMPLE
   Add-PathToRuby
#>
function Add-PathToRuby
{
    $env:Path = "$env:Path;c:\Ruby22-x64\bin;c:\Ruby2-x64-DevKit/bin"
}
