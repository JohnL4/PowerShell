<#
.SYNOPSIS
	Copies built files (from Visual Studio) to the installed product dir, in prep for remote debug.
	
.OUTPUTS
	List of PSObjects (created via New-HashObject) having the following properties:
	
	- SeqNo -- The order in which the file was copied
	- LastWriteTime -- LastWriteTime of the source file
	- From -- Full path of the source file
	- To -- Full path of the destination DIRECTORY

.EXAMPLE
	h:\bin\install-built-files.ps1 -p Main -b 3687 -fil SXA.Amb.Awm.*

.EXAMPLE
	H:\bin\install-built-files.ps1 -b 3751 -p main -c ed -regex 'SXA.ED.StatusBoard.(BUS|UI).(pdb|dll)$' | Select From,LastWriteTime,SeqNo | Out-GridView
.EXAMPLE
	h:\bin\install-built-files.ps1 -p 61-main -b 3687 -fil SXA.Amb.Awm.*
#>


param (
	[parameter(Mandatory=$True)]
	[string]
	# Product (e.g. "61" or "Main")
	$Product,
	
	[string]
	# Component (e.g., "Amb" or "SHM" or "ED")
	$Component,
	
	[parameter(Mandatory=$True)]
	[int]
	# Build number.
	$Build,
	
	[string]
	# Regular expression to recognize files to be copied (can use |-delimited alternatives).
	# May be null (in which case, everything will match).
	$Regex,
	
	[string]
	# Filter expression to be passed to Filesystem provider (probably not regex, but wildcards).
	# May be null (in which case, everything will match).
	$Filter
	)

set-strictmode -version 2.0		# PSCX tool -- comment out if not found
# set-psdebug -trace 1
	
function checkParams
{
	if (($Product -eq "61") -or ($Product -match "^61-.*") -or ($Product -eq "Main"))
	{
		$script:ProductDir = "6.1.${Build}.0"
	}
	elseif ($Product -eq "60")
	{
		$script:ProductDir = "6.0.${Build}.0"
	}
	else
	{
		throw "Product must be one of `"61`", `"61-*`", `"60`", `"Main`", was: `"$Product`""
	}
	
	# Maps from component name (subdirectory name in workspace) to possible abbreviations for that
	# component.  Component name itself is also a possible abbreviation.  User Inputs must be
	# unique prefixes of each possible abbreviation.
	$componentMap = @{
		Ambulatory	= @();
		ClinDoc		= @('SCM');
		EmergDept	= @('ED');
		SHMsg		= @();
	}
	# Flatten into a simple list of keys and values.
	$allComponents = &{$componentMap.Keys | % {echo $_; $componentMap[$_] | % {echo $_}}}
	
	$matches = @(&{$allComponents | ? {$_ -match "^${Component}"}})
	if ($matches.Count -ne 1)
	{
		throw "Component must be one of $allComponents or a unique prefix thereof, was: `"$Component`""
	}
	if ($componentMap.ContainsKey($matches[0]))
	{
		$script:Component = $matches[0]
	}
	else
	{
		# We know we have a hit, so it must be one of the values (not a key)
		# Relying on nulls and empty strings to evaluate to False.
		$script:Component = &{$componentMap.Keys | ? {$componentMap[$_] | ? {$_ -eq $matches[0]}}}
	}
	
<#	
	# Above code replaces the following:
	#
	if (($Component.Length -eq 0) `
		-or ("Ambulatory" -match "^${Component}"))
	{
		$script:Component = "Ambulatory"
	}
	elseif ("ClinDoc" -match "^${Component}")
	{
		$script:Component = "ClinDoc"
	}
	elseif ("ED" -match "^${Component}")
	{
		$script:Component = "EmergDept"
	}
	elseif ("SHM" -match "^${Component}")
	{
		$script:Component = "SHMsg"
	}
	else
	{
		throw "Component must be one of `"AMB`", `"ClinDoc`", `"ED`", `"SHM`", was: `"$Component`""
	}
#>	

	if (($Filter -eq $Null) -and ($Regex -eq $Null))
	{
		throw "One of -filter or -regex must be non-null"
	}
	if ($Filter -eq $Null)
	{
		$script:Filter = "*"
	}
	if ($Regex -eq $Null)
	{
		$script:Regex = ".*"
	}
}

function make-backup
{
	$aProductPath = $args[0]
	
	$parent = split-path -parent $aProductPath
	$child = split-path -leaf $aProductPath
	# datefn is a function that returns a timestamp suitable for use in a filename.
	$zipFile = "$child.$(datefn).zip"
	
	cd $parent
	# Write-Zip comes from PowerShell Community Extensions (pscx).
	ls $child | Write-Zip -outputPath $zipFile # -append
    # Write-Zip -path $child # -outputPath $zipFile
}

<#
.SYNOPSIS
	Builds path to working dir for given product & component
#>
function workpath
{
	param (
		$product,
		$component
		)
		
	# TODO: add to $ComponentMap, make global, so we don't need code here
	if ($component -eq "EmergDept")
	{
		$retval = "C:\work\SXA\$Product\Components\$Component"
	}
	else
	{
		$retval = "C:\work\SXA\$Product\Components\$Component\bin"
	}
	return $retval
}

# --------------------------------- main ---------------------------------

checkParams

$WorkPath = "C:\work\SXA\$Product\Components\$Component\bin"
$WorkPath = $(workpath $Product $Component)
$ProductPath = "C:\Program Files\Allscripts Sunrise\Clinical Manager Client\${ProductDir}"

Write-Host "Will copy from`n`t${WorkPath}`nto`n`t${ProductPath}"

if (Test-Path $ProductPath)
{
	$prodParent = split-path -parent $ProductPath
	$prodChild = split-path -leaf $ProductPath
	# datefn is a function that returns a timestamp suitable for use in a filename.
	# $zipFile = "$prodChild.$(datefn).zip"
	$zipFile = "_backups.$(datefn).zip"
	
	Write-Host "Backups to `"$(join-path $ProductPath $zipFile)`""
	push-location $ProductPath
#	if (Test-Path _dummy.txt)
#	{
#		# Nothing
#	}
#	else
#	{
#		New-Item -type File -name _dummy.txt
#	}
#	ls _dummy.txt | Write-Zip -outputpath $zipFile -quiet
	ls -rec $WorkPath -Filter $Filter `
		| ? {$_.FullName -match $Regex} `
		| % {
			ls $_.Name
			} `
		| Write-Zip -outputpath $zipFile `
		| Out-Host
		
	$seqNo = 0
	ls -rec $WorkPath -Filter $Filter `
		| ? {$_.FullName -match $Regex} `
		| % {
				$seqNo += 1
				cp $_.FullName $ProductPath
				@{ `
					SeqNo = $seqNo; `
					LastWriteTime = $_.LastWriteTime; `
					From = $_.FullName; `
					To = $ProductPath `
				} | New-HashObject
			}
			
	pop-location
}
else
{
	throw "Can't find product path `"$ProductPath`""
}
