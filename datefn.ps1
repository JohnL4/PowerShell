Enum FileAttribute {
	WriteTime
	CreateTime
	AccessTime
}

<#
	.SYNOPSIS
		Returns date as string, formatted suitably for use in filenames (will cause files to sort chronologically).
   .EXAMPLE
      echo "a$(datefn)b"
   .EXAMPLE
      echo a$(datefn)b
	.INPUTS
		None.
	.OUTPUTS
		Date, formatted into string.  Current implementation is YYYY-MM-DD_HHMM.
    .NOTES
        Try "%d-%b-%Y %H:00" for format "27-Oct-2015 13:00"
#>
function datefn()
{
	param(
		[string]
		# A file from which to take the date specified by the -date param
		$filename,

		[FileAttribute]
		# The date to use from the given $filename: Creation or LastAccess or LastWrite (not the UTC versions)
		$timeAttribute
	)

	if ($timeAttribute -ne $Null -and $filename.Length -eq 0) {
		throw "-timeAttribute option requires -file option"
	}
	if ($timeAttribute -eq $Null) {
		$timeAttribute = [FileAttribute]::WriteTime
	}

	$date = $Null
	if ($filename.Length -eq 0) {
		$date = [DateTime]::Now
	}
	else {
		$file = Get-ChildItem $filename
		switch ($timeAttribute)
		{
			AccessTime		{ $date = $file.LastAccessTime }
			CreateTime		{ $date = $file.CreationTime }
			WriteTime		{ $date = $file.LastWriteTime }
		}
	}
	return get-date -date $date -uformat "%Y-%m-%d_%H%M"
}