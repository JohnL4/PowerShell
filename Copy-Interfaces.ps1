<#
.SYNOPSIS
   Copy Eclipsys.Clinicals.Windows.Interfaces to designated location
.NOTES
.LINK
   about_Comment_Based_Help
.LINK
   about_Functions
#>
function Copy-Interfaces
{
    param (
      [string]
      # Subdirectory of C:\work\SXA
      $workspace
      )

    if (($workspace -eq $Null) -or ($workspace -eq ""))
    {
        throw "`workspace cannot be null or empty"
    }

    $workspacePrefix = "c:\work\SXA\$workspace"

    $bin = "$workspacePrefix\Components\ClinDoc\Bin"
    $deps = "$workspacePrefix\Components\ClinDoc\Dependencies-CD"
    
    if ($(Test-Path $workspacePrefix)  `
        -and $(Test-Path $bin)         `
        -and $(Test-Path $deps))
    {
        Write-Debug "Making Dependencies-CD writable..."
        Write-Host "`nattrib -r $workspacePrefix\Components\ClinDoc\Dependencies-CD\* /s /d" -foreground white
        attrib -r $workspacePrefix\Components\ClinDoc\Dependencies-CD\* /s /d
        Write-Debug "Made Dependencies-CD writable."

        Write-Host "`ncp $workspacePrefix\Projects\bin\Eclipsys.Clinicals.Windows.Interfaces.* $workspacePrefix\Components\ClinDoc\Bin -pass" -foreground white
        cp $workspacePrefix\Projects\bin\Eclipsys.Clinicals.Windows.Interfaces.* $workspacePrefix\Components\ClinDoc\Bin -pass
        Write-Host "`ncp $workspacePrefix\Projects\bin\Eclipsys.Clinicals.Windows.Interfaces.* $workspacePrefix\Components\ClinDoc\Dependencies-CD -pass" -foreground white
        cp $workspacePrefix\Projects\bin\Eclipsys.Clinicals.Windows.Interfaces.* $workspacePrefix\Components\ClinDoc\Dependencies-CD -pass
    }
    else
    {
        $(Test-Path $workspacePrefix) -or $(throw "`"$workspacePrefix`" does not exist") > $null
        $(Test-Path $bin) -or $(throw "`"$bin`" does not exist") > $null
        $(Test-Path $deps) -or $(throw "`"$deps`" does not exist") > $null

    }
}