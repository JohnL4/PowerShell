$ProfileParent = split-path -parent $Profile
# $ScriptDir = "H:\PowerShell" # Deprecated; directory no longer writable; obsolescent.
$ScriptDir = $ProfileParent

if (Test-Path $ScriptDir)
{
   # all good
}
else
{   
   $ScriptDir = $ProfileParent
}

# $VerbosePreference="Continue"

Write-Verbose "Sourcing common script"

. $ScriptDir\profile_common.ps1

Write-Verbose "Sourced common script"

function prompt
{
    # Note that DarkMagenta is the color slot used in the default PowerShell Start Menu shortcut for the console
    # window's background color.  Note also that, as of PS 2.0, the online help for Write-Host lists the colors in
    # color-slot order (if that makes any sense).
    $Host.UI.RawUI.WindowTitle = ("{0}@{1}" -f $env:USERNAME, $(get-location))
    Write-Host ("PS " + $(get-location) +">") -nonewline -backgroundcolor gray -foregroundcolor DarkMagenta # -foregroundcolor Green
    return " "
}

Write-Verbose "Defined function prompt()"