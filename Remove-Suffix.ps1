<#
.SYNOPSIS
  Removes a suffix delimited by "." (period) from a string.
.NOTES
  Calling this function with $null will result in an empty string being returned (not $null).
  I think this is because the use of the [string] parameter type coerces $null to the empty string at invocation.

  Consider aliasing this function to something like "rsf" to make it easier to use at the command prompt.

  New-Alias rsf Remove-Suffix
.EXAMPLE
  ls *.log | % { xfl -in $_ -out ("{0}.txt" -f (rsf $_)) }

  Process a series of log files into text files (using alias suggested in Notes).
#>
function Remove-Suffix {
    param(
        [string]
        # The string from which to remove the suffix.
        $s
    )
    $parts = @($s -split "\.")
    $n = $parts.Count
    if ($n -lt 2) {
        return $s
    } else {
        return ($parts[0..($n-2)] -join ".")
    }
}
