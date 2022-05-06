<#
.SYNOPSIS
    List processes matching on either name or description.
#>
function pss {
    param(
        [string]
        # -match pattern (REGULAR EXPRESSION, not wildcard, so use ".*" instead of "*" )
        $NameDescRegEx
    )

    ps | ? {($_.Name -match $NameDescRegEx) -or ($_.Description -match $NameDescRegEx)}
}