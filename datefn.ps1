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
#>
function datefn()
{
	get-date -uformat "%Y-%m-%d_%H%M"
}