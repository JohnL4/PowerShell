$ProfileParent = split-path -parent $Profile

. $ProfileParent\profile_common.ps1

function prompt
{
    # Note that DarkMagenta is the color slot used in the default PowerShell Start Menu shortcut for the console
    # window's background color.  Note also that, as of PS 2.0, the online help for Write-Host lists the colors in
    # color-slot order (if that makes any sense).
	$Host.UI.RawUI.WindowTitle = $(get-location)
	Write-Host ("PS " + $(get-location) +">") -nonewline -backgroundcolor gray -foregroundcolor DarkMagenta # -foregroundcolor Green
	return " "
}
