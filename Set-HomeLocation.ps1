<#
.SYNOPSIS
   Set the Home (~) directory in the FileSystem provider, if it isn't
   already set.  Useful for "Run as Administrator" PowerShell scripts.
#>

function Get-HomeLocation {
    # Using 'Run as administrator' does not set $Home, so try other variables as well
    if ($variable:Home) {
	$variable:Home
    } elseif ($env:Home) {
	$env:Home
    } elseif ($env:UserProfile) {
	$env:UserProfile
    } else {
	$null
    }
}

# If the file system has not had its home set (eg using run as administrator) try to set
# it using one of the other environmental variables so that commands like 'cd ~' work
if (-not (Get-PSProvider 'FileSystem').Home) {
    $h = Get-HomeLocation
    if ($h) {
	(Get-PSProvider 'FileSystem').Home = $h
    }
}
