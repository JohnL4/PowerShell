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
        $Pass
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
            $f = Get-ChildItem $f
        }
        if ((! $f) -or ($f.GetType().Name -ne "FileInfo")) {
            throw ("No file specified or directory specified ({0})" -f $f)
        }
        $dirName = $f.DirectoryName
        $basename = $f.BaseName
        $ext = $f.Extension
        $newFileName = ("{0}.{1}{2}" -f $basename,$(datefn -f $f),$ext)
        $newPath = Join-Path $dirName $newFileName
        $i = 1
        while (Test-Path $newPath) {
            $i += 1
            $newFileName = ("{0}.{1}.{3}{2}" -f $basename,$(datefn -f $f),$ext, $i)
            $newPath = Join-Path $dirName $newFileName
        }
        if ($Pass) {
            Copy-Item $f $newPath -pass
        } else {
            Copy-Item $f $newPath
        }
    }
    
    end {
        
    }
}