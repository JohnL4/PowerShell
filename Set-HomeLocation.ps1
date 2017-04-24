<#
.SYNOPSIS
   Set the Home (~) directory in the FileSystem provider, if it isn't
   already set.  Useful for "Run as Administrator" PowerShell scripts.
#>

function Get-HomeLocation
{
    # Using 'Run as administrator' does not set $Home, so try other variables as well
    if ($variable:Home)
    {
        Write-Verbose ("Set-HomeLocation.ps1: `$variable:Home is: {0}" -f $variable:Home)
	    $variable:Home
    }
    elseif ($env:Home)
    # Write-Warning ("{0}: Skipping check of `$variable:Home" -f $MyInvocation.ScriptName)
    # if ($env:Home)
    {
        Write-Verbose ("Set-HomeLocation.ps1: `$env:Home is: {0}" -f $env:Home)
	    $env:Home
    }
    elseif ($env:UserProfile)
    {
        Write-Verbose ("Set-HomeLocation.ps1: `$env:UserProfile is: {0}" -f $env:UserProfile)
	    $env:UserProfile
    }
    else
    {
        Write-Verbose "Set-HomeLocation.ps1: Get-HomeLocation() returning null"
	    $null
    }
}

Write-Verbose ("Set-HomeLocation.ps1: Home directory is: {0}" -f (Get-PSProvider 'FileSystem').Home)

# If the file system has not had its home set (eg using run as administrator) try to set
# it using one of the other environmental variables so that commands like 'cd ~' work

 if ((Get-PSProvider 'FileSystem').Home)
 {
     Write-Verbose "Set-HomeLocation.ps1: Not resetting home directory"
 }
 else
 {
    $h = Get-HomeLocation
    Write-Verbose ("Set-HomeLocation.ps1: New home directory will be: {0}" -f $h)
    if ($h) {
	(Get-PSProvider 'FileSystem').Home = $h
    }
 }
