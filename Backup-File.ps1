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
        $File
    )
    
    begin {
        
    }
    
    process {
        if ($_) {
            $f = $_
        } elseif ($File) {
            $f = $File
        }
        if ($f.GetType().Name -eq "String") {
            $f = ls $f
        }
        if ((! $f) -or ($f.GetType().Name -ne "FileInfo")) {
            throw ("No file specified or directory specified ({0})" -f $f)
        }
        $dirName = $f.DirectoryName
        $basename = $f.BaseName
        $ext = $f.Extension
        $newFileName = ("{0}.{1}{2}" -f $basename,$(datefn -f $f),$ext)
        $newPath = Join-Path $dirName $newFileName
        cp $f $newPath -pass
    }
    
    end {
        
    }
}