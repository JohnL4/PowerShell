<#
.SYNOPSIS
	Returns $true if the given file has nulls in the first 4 Kib.
	
.INPUTS
	String names of files or FileInfo objects.
	
.OUTPUTS
	Boolean result
#>
function HasNulls(
	# File to check
	$file
	
	# [boolean]
	# # The result to return if the input is not a file (or string filename)
	# $nonfileResult
	)
{
	try 
	{
		if ($file.GetType().ToString() -eq "System.String")
		{
			Write-Debug "arg is string"
			$fn = ((Get-Location).Path, $file) -join "\"
			Write-Debug "Opening `"$fn`""
			$reader = [IO.File]::OpenRead( $fn)
		}
		elseif ($file.GetType().ToString() -eq "System.IO.FileInfo")
		{
			Write-Debug "arg is fileinfo"
			$reader = $file.OpenRead()
		}
		else
		{
			Write-Debug "arg type unhandled"
			# if ($nonfileResult -eq $Null)
			# {
				throw @{ 
					Message = "Unrecognized object type: " + $file.GetType().ToString(); 
					Object = $file 
				} | New-HashObject
			# }
			# else
			# {
				# return $nonfileResult
			# }
		}
		$bytes = new-object byte[] 4096
		$numRead = $reader.Read($bytes, 0, $bytes.Count)
		Write-Debug "`$numRead = $numRead"
		# Write-Debug ("Read: " + ($bytes[0..($numRead-1)] -join ", "))
		
		$indexOfFirstNull = [Array]::IndexOf( $bytes[0..($numRead-1)], [byte]0)
		Write-Debug "`$indexOfFirstNull = $indexOfFirstNull"
		# for ($i = 0; $i -lt $numRead; $i += 1)
		# {
			# if ($bytes[$i] -eq 0)
			# {
				# return $true
			# }
		# }
		# return $false
		return ($indexOfFirstNull -ge 0)
	}
	finally
	{
		if ($reader)
			{ $reader.Dispose() }
	}
}