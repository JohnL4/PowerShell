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
	Write-Host ("PS " + $(get-location) +">") -nonewline -backgroundcolor Yellow
	return " "
}
