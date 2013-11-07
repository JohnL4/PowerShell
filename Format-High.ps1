<#
.SYNOPSIS
    Formats input by columns using maximum suitable column number.

.DESCRIPTION
    Format-High prints the specified property, expression, or string
    representation of input objects filling the table by columns.

    It is named in contrast to Format-Wide which prints by rows.

.EXAMPLE
    # just items
    ls c:\windows | Format-High

    # ditto in colors based on PSIsContainer
    ls c:\windows | Format-High -Print {$c = if ($args[1].PSIsContainer) {'yellow'} else {'white'}; Write-Host $args[0] -ForegroundColor $c -NoNewline}

    # just processes, not good
    ps | Format-High

    # process names, much better
    ps | Format-High Name

    # custom expression and width
    ps | Format-High {$_.Name + ':' + $_.WS} 70

    # process names in colors based on working sets
    ps | Format-High Name 70 {$c = if ($args[1].WS -gt 10mb) {'red'} else {'green'}; Write-Host $args[0] -ForegroundColor $c -NoNewline}

.NOTES
   Via http://stackoverflow.com/questions/4126409/how-to-write-a-list-sorted-lexicographically-in-a-grid-listed-by-column
#>
function Format-High {
   
    param
    (
        [object]
        # The property of the input objects to display.  If not given, uses result of .ToString().
        $Property,      # Use FullName for recursive listings?

        [int]
        # Number of characters of width to constrain the display to.  Default is terminal width (which is not available
        # in the PowerShell IDE, by the way).
        $Width = $Host.UI.RawUI.WindowSize.Width - 1,

        [string]
        # If given, all inputs will be scanned for a common prefix, which will be stripped (up through the
        # last-occurring delimiter character).
        $StripCommonPrefixDelimiter = "",

        [scriptblock]
        # A script block used to actually do the printing.  This script block receives two arguments: a string (padded
        # to the proper width) to be printed and a reference to the object described by the string (so you can make
        # decisions about formatting the string based on arbitrary object properties).
        $Print = { Write-Host $args[0] -NoNewline },

        [object[]]
        # Array of objects to be printed.  Defaults to function input.
        $InputObject
    )

    $gutterWidth = 2    # Space between columns

    Write-Debug "`$Property = $Property"

    # process the input, get strings to format
    # @ -- force array context (like Perl).
    # $input is standard ("automatic") variable holding an enumerator over the input to the function
    if ($InputObject -eq $null) { $InputObject = @($input) } 
    if ($Property -is [string]) { $strings = $InputObject | Select-Object -ExpandProperty $Property }
    elseif ($Property -is [scriptblock]) { $strings = $InputObject | ForEach-Object $Property }
    else { $strings = $InputObject }
    $strings = @(foreach($_ in $strings) { "$_" }) # Force ToString() call?

    if ($strings.Length -eq 0)
    {
        return
    }

    if (($StripCommonPrefixDelimiter -eq $Null) -or ($StripCommonPrefixDelimiter -eq ""))
    {
        # Do nothing
    }
    else
    {
        $strings = @(Strip-CommonPrefix $strings $StripCommonPrefixDelimiter)
    }

    # No need to constantly be computing string lengths (assuming they aren't somehow cached).
    [int[]]$lengths = @(foreach($_ in $strings) { $_.Length })
    $minLength = [Linq.Enumerable]::Min($lengths)

    # pass 1: find the maximum column number

    # This looks like simulated annealing, essentially.  We start with one column and squeeze down until we can't fit
    # the display into the current number of columns.  Seems like we could jumpstart this loop by dividing max element
    # length (say, 32) into display width (say, 120, which would result in at least 3 columns).  (Note: done.)

    $nbest = 1
    $bestwidths = @($Width)     # One-element array, at this point.
    $maxLength = ($lengths | Measure-Object -max).Maximum + $gutterWidth
    $minColumns = [Math]::Max( 1, [Math]::Floor( $Width / $maxLength) - 1)
    Write-Debug "`$minColumns = $minColumns"
    for($ncolumn = $minColumns; ; ++$ncolumn) {
        $nrow = [Math]::Ceiling($strings.Count / $ncolumn)
        $widths = @(
            for($s = 0; $s -lt $strings.Count; $s += $nrow) {
                $e = [Math]::Min($strings.Count, $s + $nrow)
                ($lengths[$s .. ($e - 1)] | Measure-Object -Maximum).Maximum + $gutterWidth
            }
        )
        if (($widths | Measure-Object -Sum).Sum -gt $Width) {
            break
        }
        $bestwidths = $widths
        $nbest = $ncolumn
        if ($nrow -le 1) {
            break
        }
    }

    # pass 2: print strings
    $nrow = [Math]::Ceiling($strings.Count / $nbest)
    for($r = 0; $r -lt $nrow; ++$r) {
        for($c = 0; $c -lt $nbest; ++$c) {
            $i = $c * $nrow + $r
            if ($i -lt $strings.Count) {
                & $Print ($strings[$i].PadRight($bestwidths[$c])) $InputObject[$i]
            }
        }
        & $Print "`r`n"
    }

}

<#
.SYNOPSIS
   Strips common prefix (if any) from an array of strings, returning result array
.DESCRIPTIONS
   In the case where one of the supplied strings is itself the prefix, no stripping at will be performed.
#>
function Strip-CommonPrefix
{
    param(
        [string[]]
        # Array of strings to have common prefixes stripped from
        $strings,

        [string]
        # The last character of the common prefix (if any) to be stripped.  Characters occurring in the "prefix" after
        # this final character will NOT be stripped.
        $commonPrefixDelimiter
        )

    if ($strings -eq $Null)
    {
        Write-Debug "No common prefix for null"
        return $strings
    }
    elseif ($strings.Length -le 1)
    {
        Write-Debug "No common prefix for empty or single-entry list"
        return @($strings)
    }

    [int[]]$lengths = @(foreach($_ in $strings) { $_.Length })
    
    # Find prefix candidate (shortest string)
    $minLength = [Linq.Enumerable]::Max($lengths) # Yes, Max()
    foreach ($s in $strings)
    {
        if ($s.Length -le $minLength)
        {
            $minLength = $s.Length
            $minString = $s
        }
    }
    Write-Debug "`$minLength = $minLength; `$minString = `"$minString`""

    if (($commonPrefixDelimiter -eq $Null) -or ($commonPrefixDelimiter -eq ""))
    {
        Write-Debug "No delimiter specified"
        $lastIndex = $minLength # No delimiter ==> entire candidate prefix will be used (no truncation back to last
        # delimiter).
    }
    else
    {
        # Prune candidate string back to last delimiter
        $lastIndex = $minString.LastIndexOf( $commonPrefixDelimiter) + 1
    }

    # If $lastIndex <= 0, do nothing -- a delimiter was specified but not found in the prefix candidate.  That means no
    # stripping will occur.

    if ($lastIndex -gt 0)
    {
        Write-Debug "`$lastIndex = $lastIndex"
        $minString = $minString.Substring(0, $lastIndex)
        $minLength = $minString.Length

        # Find common prefix
        $prefix = $Null
        for ($c = 0; $c -lt $minLength; $c++)
        {
            for ($s = 0; $s -lt $strings.Length; $s++)
            {
                if ($minString[$c] -ne $strings[$s][$c])
                {
                    Write-Debug ([String]::Format( "Prefix found; `$c = {0}; `$s = {1}, `$strings[`$s] = {2}", $c, $s, $strings[$s]))
                    $prefix = $minString.Substring( 0, $c)
                    break
                }
            }
            if ($prefix -ne $Null)
            {
                break
            }
        }
        if ($prefix -eq $Null)
        {
            # We got all the way through the $minString candidate prefix without failing a character comparison.  This
            # string must be the prefix.
            $prefix = $minString
        }
    
#    for ($s = 0; $s -lt $strings.Length; $s++)
#    {
#        # Write-Debug "  `$s = $s"
#        for ($c = 0; $c -lt $minLength; $c++)
#        {
#            # Write-Debug "    `$c = $c"
#            if ($minString[$c] -ne $strings[$s][$c])
#            {
#                Write-Debug "Prefix found; `$c = $c; `$s = $s; `$strings[`$s] = $strings[$s]"
#                $prefix = $minString.Substring( 0, $c)
#                break
#            }
#        }
#        if ($prefix -ne $Null)
#        {
#            break
#        }
#    }

        Write-Debug "`$prefix = `"$prefix`""
		
		# Make sure prefix ends with delimiter, otherwise fix up.
		if ($prefix.EndsWith( $commonPrefixDelimiter))
		{
			# We're good, no fixup needed.
		}
		else
		{
			$prefix = $prefix.Substring( 0, $prefix.Length - 1)
			$lastIndex = $prefix.LastIndexOf( $commonPrefixDelimiter) + 1
			$prefix = $prefix.Substring( 0, $lastIndex)
			Write-Debug "After fixup, `$prefix = $prefix"
		}

        # Strip common prefix
        if (($prefix -ne $Null) -and ($prefix -ne ""))
        {
            $strings = @(foreach ($s in $strings) { $s.Substring( $prefix.Length) })
        }
    }
    return $strings
}
