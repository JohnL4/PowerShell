<#
.SYNOPSIS

    Copy files from a source pool with backup.

.DESCRIPTION

    For every file found in destination (or reference) directory for which there is a corresponding file in the source
    pool, copy that file to the destintion directory after backing it up to the backup directory.  Note that the
    "destination" directory and the "reference" directory will probably be one and the same, so you can leave off the
    -ref option.

    -Force parameter will be used for copy to overwrite read-only files.

    This script does not operate recursively.

.NOTES

    If you want to try a dry run of this script, specify a new, empty directory for the destination, use -ref to
    indicate your original "destination" and see what it puts in the new destination.  After that, you can copy the
    results of the dry run to your real destination.

    If there are no destination files to be overwritten (length of list of destination files is 0), then the REFERENCE
    files will be backed up instead.  This will facilitate the "dry run" scenario above.

#>

param (
    [parameter( Mandatory = $true)]
    [IO.DirectoryInfo]
    # The source pool of available files for the copy.
    $srcDir,

    [parameter( Mandatory = $true)]
    [IO.DirectoryInfo]
    # The destination directory.  If it doesn't exist, it will be created.
    $destDir,

    [parameter( Mandatory = $true)]
    [string]
    # The backup directory.  Ideally, doesn't (yet) exist.
    $backupDir,

    [Switch]
    # Prevents timestamp from being appended to backup directory name.
    $noBackupTimestamp,
    
    [IO.DirectoryInfo]
    # The reference directory.
    $refDir = $destDir
)

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
Write-Verbose ("`$ErrorActionPreference = {0}" -f $ErrorActionPreference)

# -------------------------------------------------  Helper Functions  -------------------------------------------------

# For use with datefn()
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

	if ($Null -ne $timeAttribute -and $filename.Length -eq 0) {
		throw "-timeAttribute option requires -file option"
	}
	if ($Null -eq $timeAttribute) {
		$timeAttribute = [FileAttribute]::WriteTime
	}

    if ($dateOnly) {
        $timeFormat = "%Y-%m-%d"
    }
    else {
        $timeFormat = "%Y-%m-%d_%H%M%S"
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
	return get-date -date $date -uformat $timeFormat
}

<#
.SYNOPSIS
    Make the given directory and test for write permission to it.  Should throw an error for any failure.
#>
function New-WriteableDirectory()
{
    param(
        # The directory to be tested
        $dir
    )

    if (Test-Path $dir -PathType Container) {
        # We're good.
    } else {
        mkdir $dir
    }
    $testFile = (Join-Path $dir ("testfile.{0}.txt" -f (New-Guid)))
    # Should throw error on permission fail.
    New-Item $testFile -ItemType File -ea Stop
    Remove-Item $testFile
}

# -------------------------------------------------------  Main  -------------------------------------------------------

if ($noBackupTimestamp) {
    $newBackupDir = $backupDir
}
else {
    $newBackupDir = ("{0}.{1}" -f $backupDir,(datefn))
}

try {
    Write-Host -fore cyan "[Make directories and] test permissions..."
    New-WriteableDirectory $newBackupDir | Out-Null
    New-WriteableDirectory $destDir | Out-Null
}
catch {
    throw $Error[0]
}

# B is ref; A is src; C is dest
# ls B | split-path -leaf | % {join-path c:/tmp/A $_} | cp -dest C -pass

Write-Host -fore cyan "Build lists..."
$refFiles = (ls $refDir | split-path -leaf)
$srcFiles = (ls $srcDir | split-path -leaf)

# Set operations (union, intersection): https://stackoverflow.com/a/18845506/370611
$commonFileNames = Compare-Object $refFiles $srcFiles -pass -IncludeEqual -ExcludeDifferent

Write-Host -fore cyan "Take backups..."
# Suppress errors for missing files.  This might happen when copying to a new, empty destination different from
# reference, but should never happen when backing up files we're about to overwrite, because we just computed this
# list.
$existingDestFiles = $commonFileNames | % {Join-Path $destDir $_} | ls -ea SilentlyContinue
if (0 -eq $existingDestFiles.Count) {
    Write-Warning "No destination files found; backing up reference files instead"
    $commonFileNames | % {Join-Path $refDir $_} | cp -dest $newBackupDir -PassThru -ea Continue
} else {
    $commonFileNames | % {Join-Path $destDir $_} | cp -dest $newBackupDir -PassThru -ea Continue
}

Write-Host -fore cyan "Do copy..."
$commonFileNames | % {Join-Path $srcDir $_} | cp -dest $destDir -Force -PassThru
