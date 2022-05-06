<#
.SYNOPSIS
    Make a backup of the requested file, using the date of the file as part of the name.
.NOTES
    Assumes function 'datefn' has already been defined.
#>
function Backup-File {
    [CmdletBinding()]
    param (
        [Parameter( ValueFromPipeline=$true)]  
        [string]      
        $File,

        [switch]
        # Consider using -verbose (-vb) instead, if you're backing up a directory.
        $Pass
    )
    
    begin {
        
    }
    
    process {
        try {
            if ($_) {
                $f = $_
            }
            elseif ($File) {
                $f = $File
            }
            if ($f.GetType().Name -eq "String") {
                $fitem = Get-Item $f
            }
            else {
                $fitem = $f
            }
            if ((! $fitem) <# -or ($f.GetType().Name -ne "FileInfo") #> ) {
                throw ("No items found ({0})" -f $f)
            }
            if ($fitem.Count -ne 1) {
                throw ("Must operate on exactly one item, got {0}" -f $fitem.Count)
            }
            $f = $fitem[0]
            $dirName = $(if ($f.GetType().Name -eq "FileInfo") { $f.Directory } else {$f.Parent}).FullName
            $basename = $f.BaseName
            $ext = $f.Extension
            $newFileName = ("{0}.{1}{2}" -f $basename, $(datefn -f $f), $ext)
            $newPath = Join-Path $dirName $newFileName
            $i = 1
            while (Test-Path $newPath) {
                $i += 1
                $newFileName = ("{0}.{1}.{3}{2}" -f $basename, $(datefn -f $f), $ext, $i)
                $newPath = Join-Path $dirName $newFileName
            }
            Write-Verbose ("Copy {0} -> {1}" -f $f,$newPath)
            if ($Pass) {
                Copy-Item $f $newPath -pass -rec
            }
            else {
                Copy-Item $f $newPath -rec
            }
        }
        catch {
            Write-Error ("{0}`n{1}" -f $_, $_.ScriptStackTrace)
        }
    }
    
    end {
        
    }
}