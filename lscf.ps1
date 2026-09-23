$regex_opts = ([System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
          -bor [System.Text.RegularExpressions.RegexOptions]::Compiled)

# We create some variables once, globally, so we don't have to recreate it (regex construction/parsing is expensive?)
# every time we run 'lscf' (defined below), which I expect to be frequent.


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

    $supportsPsStyleFileInfo = ($PSVersionTable.PSVersion.Major -ge 7) -and
                               ($null -ne $PSStyle) -and
                               ($null -ne $PSStyle.FileInfo)

    function Test-LscfSymbolicLink {
        param([object]$Item)

        # LinkType exists for links in newer PowerShell versions.
        if (($Item.PSObject.Properties.Name -contains 'LinkType') -and
            ($null -ne $Item.LinkType) -and
            ($Item.LinkType -ne ''))
        {
            return $true
        }

        # Reparse points include symlinks/junctions on Windows.
        return ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    }

    function Test-LscfExecutable {
        param([string]$ItemExt)

        if (-not $ItemExt)
        {
            return $false
        }

        $normalizedExt = $ItemExt.ToLowerInvariant()
        $pathExtRaw = [Environment]::GetEnvironmentVariable('PATHEXT')
        $pathExtList = @()

        if ([string]::IsNullOrWhiteSpace($pathExtRaw))
        {
            $pathExtList = @('.exe', '.com', '.bat', '.cmd')
        }
        else
        {
            foreach ($ext in $pathExtRaw.Split(';'))
            {
                if (-not [string]::IsNullOrWhiteSpace($ext))
                {
                    $trimmedExt = $ext.Trim().ToLowerInvariant()
                    if ($trimmedExt[0] -ne '.')
                    {
                        $trimmedExt = '.' + $trimmedExt
                    }
                    $pathExtList += $trimmedExt
                }
            }
        }

        return $pathExtList -contains $normalizedExt
    }

    function Get-LscfColorSpec {
        param([object]$Item)

        $itemName = [string]$Item.Name
        $itemExt = [IO.Path]::GetExtension($itemName).ToLowerInvariant()

        if ($supportsPsStyleFileInfo)
        {
            if ($Item.PSIsContainer -and $PSStyle.FileInfo.Directory)
            {
                return @{ UseAnsi = $true; Style = $PSStyle.FileInfo.Directory }
            }

            if ((Test-LscfSymbolicLink -Item $Item) -and $PSStyle.FileInfo.SymbolicLink)
            {
                return @{ UseAnsi = $true; Style = $PSStyle.FileInfo.SymbolicLink }
            }

            if ($itemExt -and $PSStyle.FileInfo.Extension.ContainsKey($itemExt))
            {
                $extensionStyle = $PSStyle.FileInfo.Extension[$itemExt]
                if ($extensionStyle)
                {
                    return @{ UseAnsi = $true; Style = $extensionStyle }
                }
            }

            if ((Test-LscfExecutable -ItemExt $itemExt) -and $PSStyle.FileInfo.Executable)
            {
                return @{ UseAnsi = $true; Style = $PSStyle.FileInfo.Executable }
            }
        }

        $fallbackColor = if ($Item.PSIsContainer) {'yellow'}
                         elseif ($itemName -match '~$') {'DarkGray'}
                         elseif (Test-LscfExecutable -ItemExt $itemExt) {'Green'}
                         elseif ($ARCHIVE_REGEX.IsMatch($itemName)) {'Red'}
                         elseif ($ENCRYPTED_REGEX.IsMatch($itemName)) {'DarkCyan'}
                         elseif ($IMAGE_REGEX.IsMatch($itemName)) {'Magenta'}
                         else {'white'}

        return @{ UseAnsi = $false; Color = $fallbackColor }
    }

    function Write-LscfItem {
        param(
            [string]$Text,
            [object]$Item
        )

        $colorSpec = Get-LscfColorSpec -Item $Item
        if ($colorSpec.UseAnsi)
        {
            Write-Host ($colorSpec.Style + $Text + $PSStyle.Reset) -NoNewline
        }
        else
        {
            Write-Host $Text -ForegroundColor $colorSpec.Color -NoNewline
        }
    }

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
        if ($null -eq $Property)
        {
            $Property = "FullName"
        }
        ls -recurse:$recurse -force:$force $paths `
                | Format-High -StripCommonPrefixDelimiter:$StripCommonPrefixDelimiter -Property:$Property -Print {
                    Write-LscfItem -Text $args[0] -Item $args[1]
                }
    }
    else
    {
        Write-Debug "no recurse"
        ls -force:$force $paths | 
                Format-High -StripCommonPrefixDelimiter:$StripCommonPrefixDelimiter -Property:$Property -Print {
                    Write-LscfItem -Text $args[0] -Item $args[1]
                }
    }
}
