$ProfileParent = split-path -parent $Profile
# $ScriptDir = "H:\PowerShell" # Deprecated; directory no longer writable; obsolescent.
$ScriptDir = $ProfileParent

if (Test-Path $ScriptDir)
{
   # all good
}
else
{   
   $ScriptDir = $ProfileParent
}

# $VerbosePreference="Continue"

# Syntax highlighting - use Get-PSReadlineOption to display current options.
Set-PSReadlineOption -TokenKind String -ForegroundColor red
Set-PSReadlineOption -TokenKind Parameter -ForegroundColor white
Set-PSReadlineOption -TokenKind Comment -ForegroundColor gray
Set-PSReadlineOption -TokenKind Operator -ForegroundColor gray

Write-Verbose "Sourcing common script"

. $ScriptDir\profile_common.ps1

Write-Verbose "Sourced common script"

# Update the following two variables to modify the window title more-or-less permanently.  Otherwise, your attempt to
# update the window title will be immediately wiped out by this prompt function.
# Update these variables from other functions like this: Set-Variable -Name PROMPT_TITLE_PREFIX -Value $title -Scope Global
$PROMPT_TITLE_PREFIX = ""
$PROMPT_TITLE_SUFFIX = ""

function New-WindowTitle {
    $userLocn = ("{0}@{1}" -f $env:USERNAME, $(get-location))
    return ("{0} {1} {2}" -f $PROMPT_TITLE_PREFIX, $userLocn, $PROMPT_TITLE_SUFFIX)
}

function prompt
{
    # Note that DarkMagenta is the color slot used in the default PowerShell Start Menu shortcut for the console
    # window's background color.  Note also that, as of PS 2.0, the online help for Write-Host lists the colors in
    # color-slot order (if that makes any sense).

    if (IsAdmin)
    {
        $Host.UI.RawUI.WindowTitle = New-WindowTitle
        Write-Host ("PS " + $(get-location)) -nonewline -backgroundcolor gray -foregroundcolor DarkMagenta # -foregroundcolor Green
        Write-Host "#" -nonewline -backgroundcolor Gray -foregroundcolor DarkRed
        return " "
    }
    else
    {
        $Host.UI.RawUI.WindowTitle = New-WindowTitle
        Write-Host ("PS " + $(get-location) +">") -nonewline -backgroundcolor gray -foregroundcolor DarkMagenta # -foregroundcolor Green
        return " "
    }
}

Write-Verbose "Defined function prompt()"

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
