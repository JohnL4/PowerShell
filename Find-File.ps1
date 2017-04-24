<#
.SYNOPSIS
   Find a text file (HasNulls returns false) whose name matches the given regexp somewhere below the 
   current working directory.  See also Find-FileAny.
#>
function Find-File
{
    param (
        [string]
        # Regular expression to match filename
        $regex
        )

    # ls -rec | ? {$_.GetType().Name.Equals('FileInfo') -and (-not (HasNulls $_)) -and ($_.Name -match $regex)}
    # ls -rec | ? {$_.GetType().Name.Equals('FileInfo') -and ($_.Name -match $regex)}
    ls -rec | ? {($_.Name -match $regex) -and (-not (HasNulls $_ -nonFileResult $True))}
}

<#
.SYNOPSIS
   Find a file, regardless of whether it has nulls, whose name matches the given regexp somewhere below the 
   current working directory.  See also Find-File.
#>
function Find-FileAny
{
	param (
		[string]
		# Regular expression to match filename
		$regex
		)
		
	ls -rec | ? {$_.Name -match $regex}
}