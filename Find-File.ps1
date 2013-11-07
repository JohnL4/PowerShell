<#
.SYNOPSIS
   Find a file somewhere below the current working directory
#>
function Find-File
{
    param (
        [string]
        # Regular expression to match filename
        $regex
        )

    ls -rec | ? {$_.Name -match $regex}
}
