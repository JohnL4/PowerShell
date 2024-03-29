<#
.SYNOPSIS
    Produces info necessary to uniquely identify a file (Name, LastWriteTime, Length, MD5 Hash).
.INPUTS
    File objects or string filenames.
.NOTES
    This script takes NO arguments.  Instead files or filenames must be piped to it.  Forgive me.
.EXAMPLE
    ls | Get-Checksum | select LastWriteTime,Length,MD5Hash,Name
.NOTES
    Turns out the builtin command Get-FileHash does exactly this, although without the file-length and LastWriteTime properties.
#>
function Get-Checksum
{
    process
    {
        if ($_ -eq $null)
        {
            $sumstring = $null
        }
        else
        {
			$paramType = ($_.GetType().NameSpace + "." + $_.GetType().Name)
			# $DebugPreference = [System.Management.Automation.ActionPreference]::Continue
			Write-Debug ("`$_ type is $paramType")
			# $DebugPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
			if ($paramType -eq "System.String")
			{
				$fileItem = (get-item $_)
			}
			else
			{
				$fileItem = $_
			}
            if ($fileItem -is [IO.DirectoryInfo]) {
                $sumstring = $null
            }
            else {
                $sumstring = checksum( $fileItem)
            }
        }
        @{Name=$fileItem.Name; 
                FullName=$fileItem.FullName; 
                MD5Hash=$sumstring; 
                LastWriteTime=$fileItem.LastWriteTime; 
                Length=$fileItem.Length;
                Owner=$fileItem.GetAccessControl().Owner
                } `
			| New-HashObject
    }
}

# -----------------------------------------------------  checksum  -----------------------------------------------------

function checksum( $aFile, $aCryptoProvider)
#
# Simple function not following Verb-Noun name format because it doesn't process the pipeline.  Intended to be called by
# a function that DOES process the pipeline.
#
{
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop"
    try
    {
        if ($aCryptoProvider -eq $null)
        {
            $csp = new-object System.Security.Cryptography.MD5CryptoServiceProvider
        }
        else
        {
            $csp = $aCryptoProvider
        }
		$paramType = ($aFile.GetType().NameSpace + "." + $aFile.GetType().Name)
		# $DebugPreference = [System.Management.Automation.ActionPreference]::Continue
		Write-Debug ("`$aFile type is $paramType")
		# $DebugPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
		if ($paramType -eq "System.String")
		{
			$stream = (get-item $aFile).OpenRead()
		}
		else
		{
			$stream = $aFile.OpenRead()
		}
        $hashbytev = $csp.ComputeHash($stream)
        $sumstring = ""
        foreach ($byte in $hashbytev) 
        { 
            $sumstring += $byte.ToString("x2")
        }
    }
    finally
    {
		$ErrorActionPreference = $oldErrorActionPreference
        if ($stream -ne $null)
        {
            $stream.close() | Out-Null
        }
    }
	return $sumstring
}

