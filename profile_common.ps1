# $VerbosePreference = "Continue"

# Assumes $ProfileParent has been defined, as the directory containing the profile.
# Assumes $ScriptDir has been defined, as the directory containing all other scripts to be loaded.

$scriptName = "profile_common.ps1"

# $VerbosePreference="Inquire"

Write-Verbose ("{0}: `$ProfileParent = {1}" -f $scriptName,$ProfileParent)
Write-Verbose ("{0}: `$ScriptDir = {1}" -f $scriptName,$ScriptDir)
Write-Verbose ("{0}: `$env:PSModulePath = {1}" -f $scriptName,$env:PSModulePath)

# $VerbosePreference = "SilentlyContinue"

. $ScriptDir\Set-HomeLocation.ps1

Import-Module $ScriptDir\Modules\PowerTab

#------------------------------------------------  Amazon Web Services  ------------------------------------------------
# See http://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-started.html

# Import-Module "c:\Program Files (x86)\AWS Tools\powershell\AWSPowerShell\AWSPowerShell.psd1"
# Set-DefaultAWSRegion -Region us-east-1

#------------------------------------------------------  end AWS  ------------------------------------------------------

# $VerbosePreference = "Continue"
Write-Verbose ("`$PsVersionTable.PSVersion.Major = {0}" -f $PsVersionTable.PSVersion.Major)
# $VerbosePreference = "SilentlyContinue"

switch ($PsVersionTable.PSVersion.Major)
{
    2 {Import-Module Pscx -version 2.0 -arg ~\Pscx.UserPreferences-2.0.ps1 -pass `
            | % {"{0} {1}" -f $_.Name,$_.Version}}
    {$_ -in 3,4} {Import-Module Pscx -MinimumVersion 3.1.0.0 -arg ~\Pscx.UserPreferences-3.1.ps1 -pass `
            | % {"{0} {1}" -f $_.Name,$_.Version}}
	5 {Import-Module Pscx -MinimumVersion 3.2.0.0 -arg ~/Pscx.UserPreferences-3.2.ps1 -pass `
			| % {"{0} {1}" -f $_.Name,$_.Version}}
    default {Write-Warning ("Unexpected PowerShell version ({0}); PSCX not loaded" -f ($PsVersionTable.PSVersion -join '.'))}
}

. $ScriptDir\Add-PathToRuby.ps1
. $ScriptDir\Copy-Interfaces.ps1
. $ScriptDir\datefn.ps1
. $ScriptDir\EggTimer.ps1
. $ScriptDir\Find-File.ps1
. $ScriptDir\Format-Columns.ps1
. $ScriptDir\Format-High.ps1
. $ScriptDir\Get-Checksum.ps1
. $ScriptDir\HasNulls.ps1
. $ScriptDir\lscf.ps1
. $ScriptDir\oss.ps1
. $ScriptDir\ScanSrc.ps1
. $ScriptDir\Show-Message.ps1
. $ScriptDir\slay.ps1
. $ScriptDir\waitfor.ps1

# --------------------------------------------------  find-and-alias  --------------------------------------------------
<#
.SYNOPSIS
   Create an alias to the first of several paths found.
#>
function find-and-alias
{
    param (
        [string]
        # The alias to be created
        $alias,

        [string[]]
        # The list of paths to be tested
        $paths
        )

    # $DebugPreference = [System.Management.Automation.ActionPreference]::Continue
    write-debug "alias: $alias; paths: $paths"
    
    $found = $False
    foreach ($path in $paths)
    {
        write-debug "checking path: $path"
        if (Test-Path $path)
        {
            new-alias $alias $path -scope global
            $found = $True
            break
        }
    }
    write-debug "found: $found"
    if ($found)
    {
        # all good
    }
    else
    {
        write-warning "No path found, no '$alias' alias"
    }
}
# ---------------------------------------------------------    ---------------------------------------------------------

new-alias 		cols	Format-Columns
find-and-alias 	ec 		"c:\usr\local\emacs-24.3\bin\emacsclientw.exe","C:\emacs\emacs-24.2\bin\emacsclientw.exe","C:\emacs\emacs-23.3\bin\emacsclientw.exe"
new-alias		ff		Find-File
new-alias		ffa		Find-FileAny
new-alias 		hi 		Format-High
find-and-alias  np		@('C:\Program Files\Notepad++\notepad++.exe',
                          'C:\Program Files (x86)\Notepad++\notepad++.exe')
new-alias 		os		Out-String
new-alias 		ss		Select-String
new-alias 		sum		Get-Checksum
find-and-alias	svcutil	@("C:\Program Files\Microsoft SDKs\Windows\v8.0A\bin\NETFX 4.0 Tools\svcutil.exe",
                          "C:\Program Files (x86)\Microsoft SDKs\Windows\v8.0A\bin\NETFX 4.0 Tools\svcutil.exe",
                          "C:\Program Files\Microsoft SDKs\Windows\v7.0A\bin\NETFX 4.0 Tools\svcutil.exe",
                          "C:\Program Files\Microsoft SDKs\Windows\v7.0A\bin\svcutil.exe")
new-alias       xm      Show-Message

# -------------------------------------------------  Global variables  -------------------------------------------------

$regex_opts = ([System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
          -bor [System.Text.RegularExpressions.RegexOptions]::Compiled)

# We create some variables once, globally, so we don't have to recreate it (regex construction/parsing is expensive?)
# every time we run 'lscf' (defined below), which I expect to be frequent.

New-Variable -name EXECUTABLE_REGEX -option ReadOnly `
        -description "Regular expression that recognizes executable files by their suffix" `
        -value (New-Object System.Text.RegularExpressions.Regex( '\.(exe|bat|cmd|py|pl|ps1|psm1|vbs|rb|reg)$', $regex_opts))

New-Variable -name ARCHIVE_REGEX -option ReadOnly `
        -description "Regular expression that recognizes archive files by their suffix" `
        -value (New-Object System.Text.RegularExpressions.Regex( '\.(zip|gz|gzip|bz2|7z)$', $regex_opts))

New-Variable -name IMAGE_REGEX -option ReadOnly `
        -description "Regular expression that recognizes image files by their suffix" `
        -value (New-Object System.Text.RegularExpressions.Regex( '\.(png|bmp|gif|ico|jpe?g)$', $regex_opts))

Remove-Variable regex_opts


# ----------------------------------------------  Environment variables  -----------------------------------------------

$env:LESS = "-Mi -j10 -z-3"

# ---------------------------------------------  Aliases (tiny functions)  ---------------------------------------------

<#
.SYNOPSIS
   Open new PowerShell console window.

.DESCRIPTION
   If you just want a new session (subshell) in your current window, just run the powershell.exe directly.

.EXAMPLE
   C:\> posh

   Opens a new window.

.EXAMPLE
   C:\> powershell

   Runs a new PowerShell session in the current window.
#>
function posh {
    # Slightly sketchy cheat (maybe?) but it works. :)
    # Note that shortcut is here: 
    # C:\Users\j6l\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Windows PowerShell.lnk
    # but that might be user/machine-specific.
    # After your window comes up for the first time, you can configure it to look the same as your "normal" window
    # started via the PowerShell shortcut (or different, if you prefer).
    invoke-item $PSHOME\powershell.exe
}
