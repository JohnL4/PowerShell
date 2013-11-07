$ProfileParent = split-path -parent $Profile

. $ProfileParent\profile_common.ps1

function prompt
{
	Write-Host ("PS " + $(get-location) +">") -nonewline -backgroundcolor Yellow
	return " "
}
