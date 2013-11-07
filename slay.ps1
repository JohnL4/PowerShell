<#
.SYNOPSIS
   Kills all processes matching the given name
#>
function slay
{
    param (
        [string[]]
        # Process name(s) to kill
        $processNames,

        [switch]
        $whatif,

        [switch]
        $confirm
        )

    foreach ($procName in $processNames)
    {
        ps | ? {$_.Name -match $procName} | kill -pass -whatif:$whatif -confirm:$confirm
    }
}
