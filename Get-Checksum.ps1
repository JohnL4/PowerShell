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
            $sumstring = checksum( $_)
        }
        @{File=$_; MD5Hash=$sumstring}
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
        $stream = (get-item $aFile).OpenRead()
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
