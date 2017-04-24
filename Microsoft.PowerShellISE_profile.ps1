$ProfileParent = split-path -parent $Profile
$ScriptDir = "H:\PowerShell"

if (Test-Path $ScriptDir)
{
   # all good
}
else
{   
   $ScriptDir = $ProfileParent
}

. $ScriptDir\profile_common.ps1

function prompt
{
    # Note that DarkMagenta is the color slot used in the default PowerShell Start Menu shortcut for the console
    # window's background color.  Note also that, as of PS 2.0, the online help for Write-Host lists the colors in
    # color-slot order (if that makes any sense).
	# Write-Host ("PS " + $(get-location) +">") -nonewline -backgroundcolor Yellow
    Write-Host ("PS " + $(get-location) +">") -nonewline -backgroundcolor gray -foregroundcolor DarkBlue # -foregroundcolor Green
	return " "
}
