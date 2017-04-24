<#
.SYNOPSIS
   Deploys the given version of Sunrise from a build server to the user's workstation.
   
.EXAMPLE
	deploy-sunrise.ps1 -b 1111 -op in -mo rel -comp "gateway","SXA-SCM-Client","SXA-AMB-Client","SXA-ED-Client"
	
	Installs all the components our team is working with.  Generally, the gateway doesn't need
	re-installing.
.EXAMPLE
	deploy-sunrise.ps1 -b 3696
	
	Simplest deploy.
#>


# 'fool emacs with closing quote

param (
    [string]
    # "install" or "uninstall"
    $operation = "install",
    
    [int]
    # Build number
    $build,
    
    [string]
    # "release" or "debug"
    $mode = "debug",
    
    [string]
    # One of:
    #    - SXA61
    #    - SXA60
    $product = "SXA61",
	
	[string]
	# One of:
	#	- MLVCMFS01
	#	- POLARIS
	$server = "POLARIS",
    
    [string[]]
    # Array of products to install.  The gateway is denoted by "gateway".
    $components = ("gateway","SXA-SCM-Client","SXA-AMB-Client","SXA-ED-Client")
)

# $SERVER = "mlvcmfs01"
# $SERVER = "polaris"

set-strictmode -version 2.0		# PSCX tool -- comment out if not found
# set-psdebug -trace 1

# ------------------------------------------

<#
.DESCRIPTION
    Validates script parameters and processes them (e.g., by canonicalizing, expanding, etc.)
    Updates script variables $mode, $modeDir, $productDir.
#>
function checkParams
{
    # get-variable -scope local
    
    if ("install".StartsWith( $operation, [StringComparison]::CurrentCultureIgnoreCase))
    {
        $script:operation = "install"
    }
    elseif ("uninstall".StartsWith( $operation, [StringComparison]::CurrentCultureIgnoreCase))
    {
        $script:operation = "uninstall"
        Write-Host -foreground Cyan "Uninstalling apps -- Be sure to select REMOVE or UNINSTALL for each installer run."
    }
    else
    {
        throw "Unexpected operation: $operation"
    }
    
    if ($operation -eq "install")
    {
        # good
    }
    elseif ($operation -eq "uninstall")
    {
        # good
    }
    else
    {
        throw "Only `"install`" or `"uninstall`" operations are supported."
    }
    
    if ($build -eq 0) { throw "-build must be specified" }
    
	if ("MLVCMFS01".startsWith( $server, [StringComparison]::CurrentCultureIgnoreCase))
	{
		$script:server = "MLVCMFS01"
	}
	elseif ("POLARIS".startsWith( $server, [StringComparison]::CurrentCultureIgnoreCase))
	{
		$script:server = "POLARIS"
	}
	
    switch ($product)
    {
        "SXA61"
        {
			switch ($server)
			{
				"MLVCMFS01"		{ $script:productDir = "SXA61\Sunrise61GA" }
				"POLARIS"		{ $script:productDir = "SUN-BOYS\Sunrise61GA" }
			}
				
            # $script:productDir = "SXA61\Sunrise61GA"
            # $script:productDir = "SUN-BOYS\Sunrise61GA"
        }
        "SXA60"
        {
            switch ($server)
            {
                "MLVCMFS01"		{ $script:productDir = "SXA60\Sunrise60GA" }
                "POLARIS"		{ $script:productDir = "SUN-BOYS\Sunrise60GA" }
            }
        }
        default {throw "Unrecognized product: $product"}
    }

    if ("release".StartsWith( $mode, [StringComparison]::CurrentCultureIgnoreCase))
    {
        $script:mode = "release"
        $script:modeDir = "VSMode-Release"
    }
    elseif ("debug".StartsWith( $mode, [StringComparison]::CurrentCultureIgnoreCase))
    {
        $script:mode = "debug"
        $script:modeDir = "VSMode-Debug"
    }
    else
    {
        throw "Unrecognized mode, must be one of `"release`" or `"debug`": $mode"
    }
    # get-variable -scope local

}

# ------------------------------------------

<#
.SYNOPSIS
    Alias for Test-Path
#>
function tp
{
	$filename = $args[0]
    if (Test-Path $filename)
    {
        # good
    }
    else
    {
        throw "Non-existent: $filename"
    }
}

# ------------------------------------------

# path = \\mlvcmfs01\SXA61\Sunrise61GA\VSMode-Release\DROP\3673\I386

checkParams

$pathVerified = $False
$triedCount = 0
while (-not $pathVerified)
{
    try
    {
        $pathPrefix = join-path "\\$server" $productDir            ; tp $pathPrefix
        $pathPrefix = join-path $pathPrefix $modeDir               ; tp $pathPrefix
        $pathPrefix = join-path $pathPrefix "DROP\$build\I386"     ; tp $pathPrefix
        $pathVerified = $True
    }
    catch
    {
        write-warning $Error[0]
        $triedCount += 1
        if ($triedCount -ge 4)      # two modes * two servers
        {
            throw "Can't find the requested build (All possible paths exhausted)."
        }

        # Switch modes after every try
        if ($mode -eq "release")
        {
            $mode = "debug"
        }
        else
        {
            $mode = "release"
        }

        # Switch servers after every two tries (for each mode)
        if (($triedCount % 2) -eq 0)
        {
            if ($server -eq "POLARIS")
            {
                $server = "MLVCMFS01"
            }
            else
            {
                $server = "POLARIS"
            }
        }
        checkParams             # We know they're valid, but the new values imply other settings (which checkParams handles)
    }
}

if ($operation -eq "install")
{
    [string[]]$componentsArray = $components
}
else
{
    [string[]]$componentsArray = @()
    for ($i = $components.Length - 1; $i -ge 0; $i--)
    {
        $componentsArray += $components[$i]
    }
}

foreach ($component in $componentsArray) {
    if ("gateway".StartsWith( $component, [StringComparison]::CurrentCultureIgnoreCase))
    {
        $componentPath = "HeliosInstallers\Allscripts-Gateway"
    }
    else
    {
        $componentPath = $component
    }
    $installerPath = (join-path (join-path $pathPrefix $componentPath) "setup.exe")
    try
    {
        tp $installerPath
        echo "Running $installerPath"
        start-process -filepath $installerPath -wait
    }
    catch
    {
        write-warning $Error[0]
        $continue = read-host "Continue? [y/n] "
        if ($continue -eq "y")
        {
            # nothing, keep going
        }
        else
        {
            throw $Error[0]
        }
    }
}

# set-psdebug -off

