<#
.SYNOPSIS
    Returns given assembly's strong name, which includes its version and public key token (if any).
#>
function Get-AssemblyStrongName
{
    param(
        [parameter( Mandatory = $True)]
        [string]
        # The path to the assembly you're interested in
        $assemblyPath
    )
    
    [System.Reflection.AssemblyName]::GetAssemblyName($assemblyPath).FullName 
}
