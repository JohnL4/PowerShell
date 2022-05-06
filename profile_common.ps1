# Assumes $ProfileParent has been defined, as the directory containing the profile.
# Assumes $ScriptDir has been defined, as the directory containing all other scripts to be loaded.

# $VerbosePreference="Inquire"

<#
.SYNOPSIS
    Returns true iff current PowerShell session is running with elevated privileges (i.e., "As Administrator").
.NOTES
    From http://ss64.com/ps/syntax-elevate.html
#>
function IsAdmin
{
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

Write-Verbose ("{0}: `$ProfileParent = {1}" -f "profile_common.ps1",$ProfileParent)
Write-Verbose ("{0}: `$ScriptDir = {1}" -f "profile_common.ps1",$ScriptDir)
Write-Verbose ("{0}: `$env:PSModulePath = {1}" -f "profile_common.ps1",$env:PSModulePath)
Write-Verbose ("IsAdmin: {0}" -f $(IsAdmin))

if (Test-Path "C:\Users\j6l")
{
    # $Home = "C:\Users\j6l"
    $env:Home = "C:\Users\j6l"
}

. $ScriptDir\Set-HomeLocation.ps1

# $VerbosePreference = "SilentlyContinue"

Import-Module PowerTab -ArgumentList "$ProfileParent\PowerTabConfig.xml"

#------------------------------------------------  Amazon Web Services  ------------------------------------------------
# See http://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-started.html

# Import-Module "c:\Program Files (x86)\AWS Tools\powershell\AWSPowerShell\AWSPowerShell.psd1"
# Set-DefaultAWSRegion -Region us-east-1

#------------------------------------------------------  end AWS  ------------------------------------------------------

switch ($PsVersionTable.PSVersion.Major)
{
    2 {Import-Module Pscx -version 2.0 -arg ~\Pscx.UserPreferences-2.0.ps1 -pass `
            | % {"{0} {1}" -f $_.Name,$_.Version}}
    {$_ -in (3,4,5)} {Import-Module Pscx -MinimumVersion 3.2.0.0 -arg ~\Pscx.UserPreferences-3.2.ps1 -pass `
            | % {"{0} {1}" -f $_.Name,$_.Version}}
    default {Write-Warning ("Unexpected PowerShell version ({0}); PSCX not loaded" -f ($PsVersionTable.PSVersion -join '.'))}
}

. $ScriptDir\Add-PathToRuby.ps1
. $ScriptDir\Backup-File.ps1
# . $ScriptDir\Copy-Interfaces.ps1
. $ScriptDir\datefn.ps1
. $ScriptDir\EggTimer.ps1
. $ScriptDir\Find-File.ps1
. $ScriptDir\Format-Columns.ps1
. $ScriptDir\Format-High.ps1
. $ScriptDir\Get-Checksum.ps1
. $ScriptDir\HasNulls.ps1
. $ScriptDir\lscf.ps1
. $ScriptDir\oss.ps1
. $ScriptDir\pss.ps1
. $ScriptDir\Remove-Suffix.ps1
. $ScriptDir\ScanSrc.ps1
. $ScriptDir\Show-Message.ps1
. $ScriptDir\slay.ps1
. $ScriptDir\sudo.ps1
. $ScriptDir\waitfor.ps1

# --------------------------------------------------  Find-Alias  --------------------------------------------------
<#
.SYNOPSIS
   Create an alias to the first of several paths found.
#>
function Find-Alias
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

# ----------------------------------------------------  Get-Latest  ----------------------------------------------------

<#
.SYNOPSIS
    Returns the latest item in a path, by sorting by reverse lexical order and taking the first item
#>
function Get-Latest
{
    param(
        [string]
        # Parent directory
        $directory,

        [switch]
        # Find the latest file in the given directory, rather than the latest sub-directory
        $file
    )

    if ($file)
    {
        $type = [System.IO.FileInfo]
    }
    else
    {
        $type = [System.IO.DirectoryInfo]
    }
    
    $retval = (ls $directory | ? {$_.GetType() -eq $type} | sort -desc | select -first 1)
    return $retval
}

# --------------------------------------------------  End Get-Latest  --------------------------------------------------

# -------------------------------------------------  Global variables  -------------------------------------------------

# ----------------------------------------------  Environment variables  -----------------------------------------------

if (Test-Path "c:/usr/local/Java") {
    $env:JAVA_HOME = $(ls c:/usr/local/Java | sort CreationTime -desc | select -first 1 FullName).FullName
}
else {
    Write-Warning "No Java"
}

$env:LESS = "-Mi -j10 -z-3"

# -----------------------------------------------------  Aliases  ------------------------------------------------------

new-alias 		cols	Format-Columns
Find-Alias      ec 		"C:\usr\local\emacs\26.3\bin\emacsclientw.exe"
Find-Alias      entlibconfig "c:\usr\local\EnterpriseLibrary6.0\EntLibConfig.exe"
new-alias		ff		Find-File
new-alias		ffa		Find-FileAny
# Find-Alias		git		"C:\Program Files\Git\cmd\git.exe"
new-alias 		hi 		Format-High

Find-Alias      jar     @("$env:JAVA_HOME\bin\jar.exe")
Find-Alias      java    @("$env:JAVA_HOME\bin\java.exe")
Find-Alias      javac   @("$env:JAVA_HOME\bin\javac.exe")

Find-Alias      mvn     @("c:\usr\local\apache-maven-3.5.2\bin\mvn.cmd")
Find-Alias      np		@('C:\Program Files\Notepad++\notepad++.exe',
                          'C:\Program Files (x86)\Notepad++\notepad++.exe')
new-alias 		os		Out-String
New-Alias       rsf     Remove-Suffix
new-alias       sel     Select-Object # 'select' is still too long
new-alias 		sum		Get-Checksum
new-alias       swm     SwapMouse
Find-Alias      svcutil	@("C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.2 Tools\SvcUtil.exe")
# Don't need 'vsc' alias because VS Code installs its own command: 'code' (which maps to 'code.cmd' on windows).
# Find-Alias		vsc		@("${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe",
#                           "C:\Program Files\Microsoft VS Code\Code.exe")
Find-Alias      xfl     @("C:\work\sxa\LocalTools\Xform-NLog.ps1")
new-alias       xm      Show-Message

# ----------------------------------------------------  Functions  -----------------------------------------------------

function iisx { 
    & "c:\Program Files\IIS Express\iisexpress.exe" /path:"C:\Users\j6l\OneDrive - Pulse8 Inc\Shared-With-Everyone" 
}

function labelwin {
    param(
        [string]
        # String label for current console window
        $title
    )
    # $PROMPT_TITLE_PREFIX defined in Microsoft.PowerShell_profile.ps1
    Set-Variable -Name PROMPT_TITLE_PREFIX -Value $title -Scope Global 
    $host.ui.RawUI.WindowTitle = New-WindowTitle
}

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
    invoke-item $PSHOME\powershell.exe # TODO: use start-process?
}

function        umlet   { start-process c:/usr/local/Umlet/umlet.jar }
function        yed     { start-process "$((Get-Latest c:/usr/local/yed).FullName)/yed.jar" }
