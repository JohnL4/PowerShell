$regex_opts = ([System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
          -bor [System.Text.RegularExpressions.RegexOptions]::Compiled)

# We create some variables once, globally, so we don't have to recreate it (regex construction/parsing is expensive?)
# every time we run 'lscf' (defined below), which I expect to be frequent.

New-Variable -name EXECUTABLE_REGEX -option ReadOnly `
        -description "Regular expression that recognizes executable files by their suffix" `
        -value (New-Object System.Text.RegularExpressions.Regex( '\.(exe|bat|cmd|py|pl|ps1|psm1|vbs|rb|reg)$', $regex_opts))

New-Variable -name ARCHIVE_REGEX -option ReadOnly `
        -description "Regular expression that recognizes archive files by their suffix" `
        -value (New-Object System.Text.RegularExpressions.Regex( '\.(zip|gz|gzip|bz2|7z)$', $regex_opts))

New-Variable -name ENCRYPTED_REGEX -option ReadOnly `
        -description "Regular expression that recognizes encrypted files by their suffix" `
        -value (New-Object System.Text.RegularExpressions.Regex( '\.(gpg|pgp)$', $regex_opts))

New-Variable -name IMAGE_REGEX -option ReadOnly `
        -description "Regular expression that recognizes image files by their suffix" `
        -value (New-Object System.Text.RegularExpressions.Regex( '\.(bmp|gif|ico|jpe?g|png|svg|wmv|xcf)$', $regex_opts))

Remove-Variable regex_opts

<#
.SYNOPSIS 
   Lists current location (directory), color-coding containers (directories) yellow and non-containers (files) white.

.NOTES
   Takes name from an Unix alias:  lscf == ls --colors -F to show colors and use trailing flag characters to indicate file type.
#>
function lscf {
    param ([string[]]
           # The item(s) to list.
           $paths,
           
           [switch]
           # Passed to ls
           $recurse,

           [switch]
           # Passed to ls
           $force,

           [string]
           # Forced to $True if -recurse is on
           $StripCommonPrefixDelimiter = "\",

           [string]
           # The property to display (default is result of .ToString() for non-recursive; FullName for recursive).
           $Property
           )

    # The following doesn't work too well.  Format-High needs to be taught the trick of stripping a common prefix (or
    # doing it automatically). 
#    if ($recurse) {
#        $prefixLength = $PWD.Path.Length + 1 # Common prefix of each directory element's full name, including trailing slash.
#        if ($args.Length -eq 1) {
#            $prefixLength = $prefixLength + 1 + $args[0].Length # Include trailing slash.
#        }
#        Write-Debug "`$prefixLength = $prefixLength"
#    }

    Write-Debug "`$Args = $Args"
    Write-Debug "`$PSBoundParameters = $PSBoundParameters"
    Write-Debug ([String]::Format( "`$PSBoundParameters.Count = {0}", $PSBoundParameters.Count))
    foreach ($a in $PSBoundParameters.Keys)
    {
        Write-Debug ([String]::Format( "  {0} = {1}", $a, $PSBoundParameters[$a]))
    }
    Write-Debug "`$StripCommonPrefixDelimiter = $StripCommonPrefixDelimiter"

    if ($recurse -or ($paths.Length -gt 1))
    {
        Write-Debug "recurse"
        if ($Property -eq $Null)
        {
            $Property = "FullName"
        }
        ls -recurse:$recurse -force:$force $paths `
                | Format-High -StripCommonPrefixDelimiter:$StripCommonPrefixDelimiter -Property:$Property -Print {
                    $c = if ($args[1].PSIsContainer) {'yellow'} 
                    elseif ($args[1].Name -match '~$') {'DarkGray'} 
                    elseif ($EXECUTABLE_REGEX.IsMatch( $args[1].Name)) {'Green'} 
                    elseif ($ARCHIVE_REGEX.IsMatch( $args[1].Name)) {'Red'}
                    elseif ($ENCRYPTED_REGEX.IsMatch( $args[1].Name)) {'DarkCyan'}
                    elseif ($IMAGE_REGEX.IsMatch( $args[1].Name)) {'Magenta'}
                    else {
                                'white'
                            }
                    Write-Host $args[0] -ForegroundColor $c -NoNewline
                }
    }
    else
    {
        Write-Debug "no recurse"
        ls -force:$force $paths | 
                Format-High -StripCommonPrefixDelimiter:$StripCommonPrefixDelimiter -Property:$Property -Print {
                    $c = if ($args[1].PSIsContainer) {'yellow'}
                    elseif ($args[1].Name -match '~$') {'DarkGray'}
                    elseif ($EXECUTABLE_REGEX.IsMatch( $args[1].Name)) {'Green'} 
                    elseif ($ARCHIVE_REGEX.IsMatch( $args[1].Name)) {'Red'}
                    elseif ($ENCRYPTED_REGEX.IsMatch( $args[1].Name)) {'DarkCyan'}
                    elseif ($IMAGE_REGEX.IsMatch( $args[1].Name)) {'Magenta'}
                    else {
                                'white'
                            }
                    Write-Host $args[0] -ForegroundColor $c -NoNewline
                }
    }
}
