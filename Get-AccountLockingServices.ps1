<#
.SYNOPSIS
    Returns a list of Services, IIS Application Pools, and Scheduled Tasks that might cause your account to be locked because
    they have locally hardcoded passwords.
.DESCRIPTION
    Script must be run at an ELEVATED PowerShell prompt.
#>
param (
)

# ----------------------------------------------------  Constants  -----------------------------------------------------



# ----------------------------------------------------  Functions  -----------------------------------------------------

function Get-AccountLockingServices
{
    param (
    )
    # List available namespaces with: gwmi -Namespace root -Class __Namespace | select Name
    $appPools = gwmi -namespace "root\WebAdministration" -class ApplicationPool
    $appPools | select Name,ManagedPipelineMode,PassAnonymousToken | oh

    # Note: the following doesn't really return a usable object when we select ProcessModel.  Instead, we should
    # probably 
    $appPools | select ProcessModel | select IdentityType,UserName | oh 

    # From https://stackoverflow.com/a/42101170/370611 :
    Import-Module WebAdministration;
    Get-ChildItem -Path IIS:\AppPools\ `
            | Select-Object name, state, managedRuntimeVersion, managedPipelineMode, @{e={$_.processModel.username};l="username"}, <#@{e={$_.processModel.password};l="password"}, #> @{e={$_.processModel.identityType};l="identityType"} `
            | format-table -AutoSize
}

# -------------------------------------------------------  Main  -------------------------------------------------------

Get-AccountLockingServices
