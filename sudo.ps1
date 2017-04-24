<#
.SYNOPSIS
    Run an executable as Administrator
.PARAMETER exe
#>
function sudo
{
    param (
        [string]
        # The executable to be run
        $exe,

        [string[]]
        # Arguments to the executable specified by -exe
        $argv
        #
    )

    if ($argv) {

        # Unicode characters are "{LEFT,RIGHT}-POINTING DOUBLE ANGLE QUOTATION MARK".

        $argsMsg = ($argv | % {"«{0}»" -f $_}) -join ","
        Write-Verbose ("Start-Process «{0}» -ArgumentList {1}" -f $exe,$argsMsg)
        Start-Process $exe -ArgumentList $argv -Verb RunAs -Wait
    }
    else {
        Write-Verbose "Start-Process `"$exe`" -Verb RunAs -Wait"
        Start-Process $exe -Verb RunAs -Wait
    }
    # 
}
