<#
.SYNOPSIS
	Returns $true if the given file has nulls in the first block (currently 1024 characters, which may be unicode).
	
.INPUTS
	String names of files or FileInfo objects.
	
.OUTPUTS
	Boolean result
	
.EXAMPLE
	ls -rec | ? {[IO.FileInfo].IsAssignableFrom($_.GetType()) -and (-not (HasNulls $_ ))} | ss -list '\bEDTab\b' | ogv
#>
function HasNulls
    (
	# File to check
	$file,
	
	[boolean]
	# The result to return if the input is not a file (or string filename)
	$nonfileResult
	)

{

#     Param
#         (
#             [parameter(Mandatory=$True, ValueFromPipeline=$True)]
#             [IO.FileSystemInfo[]]
#             $file
#         )
    Process
    {
        if ($file -eq $Null) { $file = $_ }
	    try 
	    {
            $ftype = $file.GetType().ToString()
		    if ($ftype -eq "System.String")
		    {
			    Write-Debug "arg is string"
			    $fn = ((Get-Location).Path, $file) -join "\"
			    Write-Debug "Opening `"$fn`""
			    $reader = [IO.File]::OpenRead( $fn)
		    }
		    elseif ($ftype -eq "System.IO.FileInfo")
		    {
			    Write-Debug "arg is fileinfo"
			    $reader = $file.OpenRead()
		    }
            elseif ($ftype -eq "System.IO.DirectoryInfo")
            {
                Write-Debug ('{0} is directory' -f $file.FullName)
                return $nonFileResult
            }
			else
			{
                Write-Debug ('arg name, type: {0}, {1}' -f $file.ToString(),$ftype)
				return $nonfileResult
			}
# 		    else
# 		    {
# 			    Write-Debug "arg type unhandled"
# 			    # if ($nonfileResult -eq $Null)
# 			    # {
# 				throw @{ 
# 					Message = "Unrecognized object type: " + $ftype; 
# 					Object = $file 
# 				} | New-HashObject
# 		    }
            $streamReader = New-Object 'IO.StreamReader' $reader,$True # $True ==> auto-detect encoding
            Write-Debug ("Encoding for '{0}': {1}" -f $reader.Name,$streamReader.CurrentEncoding)
            
		    $chars = new-object char[] 1024
		    $numRead = $streamReader.Read($chars, 0, $chars.Count)
		    Write-Debug "`$numRead = $numRead"
		    Write-Debug ("Read: " + ($chars[0..([Math]::Min(16, $numRead-1))] -join ", "))
		    
		    $indexOfFirstNull = [Array]::IndexOf( $chars[0..($numRead-1)], [char]0)
		    Write-Debug "`$indexOfFirstNull = $indexOfFirstNull"
            $retval = ($indexOfFirstNull -ge 0)

		    return $retval
	    }
	    finally
	    {
		    if ($streamReader)
			{ $streamReader.Dispose() }
            $file = $Null
	    }
    }
}