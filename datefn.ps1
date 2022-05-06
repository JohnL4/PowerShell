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
		# The date to use from the given $filename: LastWrite (the default), Creation, or LastAccess (not the UTC versions)
		$timeAttribute,

        [switch]
        # Use only the date part of the selected file attribute, not the time part (i.e., only mm/dd/yyyy, not hh:mm).
        $dateOnly
	)

	if ($timeAttribute -ne $Null -and $filename.Length -eq 0) {
		throw "-timeAttribute option requires -file option"
	}
	if ($timeAttribute -eq $Null) {
		$timeAttribute = [FileAttribute]::WriteTime
	}

    if ($dateOnly) {
        $timeFormat = "%Y-%m-%d"
    }
    else {
        $timeFormat = "%Y-%m-%d-%H%M"
    }

	$date = $Null
	if ($filename.Length -eq 0) {
		$date = [DateTime]::Now
	}
	else {
		$file = Get-Item $filename
		switch ($timeAttribute)
		{
			AccessTime		{ $date = $file.LastAccessTime }
			CreateTime		{ $date = $file.CreationTime }
			WriteTime		{ $date = $file.LastWriteTime }
		}
	}
	return get-date -date $date -uformat $timeFormat
}
