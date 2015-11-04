<#
	.SYNOPSIS
		Sleeps (blocking) for the specified time and then pops up a message box containg
		the given message text.

	.DESCRIPTION
		See Synopsis.

	.PARAMETER MinutesSeconds
		A string in the form "[min][:sec]".  Both parts are optional, but the string itself
		is not.  The first part (before the colon) is wait time in minutes; the second part,
		wait time in seconds.

	.PARAMETER Message
		A string containing the message to be displayed.  PowerShell syntax tip:  no special
		characters in the string (spaces are special) mean no quotes are required.

	.INPUTS
		None.

	.OUTPUTS
		None.

	.EXAMPLE
		EggTimer 5 tea

		Pops up a message box containing "tea" after five minutes.

	.EXAMPLE
		EggTimer 4:30 "your tea is done"

		Pops up a message after four and a half minutes containing "your tea is done".
#>
function EggTimer( [String] $MinutesSeconds, [String] $Message)
{
	# Characters not allowed in message box caption.
	$NOT_IN_CAPTION_RE = New-Object System.Text.RegularExpressions.Regex "[`n`r`t]+"
	$SUCCESSFUL_MESSAGE = "The message was successfully sent"
	
	$ms = $MinutesSeconds -split ":"
	$time = ($ms[0] -as "int") * 60 + $ms[1]
	# echo "Will wait for $time seconds"
	$caption = "EggTimer: $Message"
	$caption = $NOT_IN_CAPTION_RE.Replace( $caption, " ")
	[Threading.Thread]::Sleep( $time * 1000)
   
   Write-Host -fore cyan $Message

    if (Test-Path alias:xm)
    {
        xm $Caption
    }
    else
    {
	    $OldErrorActionPreference = $ErrorActionPreference
	    $ErrorActionPreference = "Stop"
	    try
	    {
		    $netSendResult = net send $env:COMPUTERNAME "$Message"
	    }
	    catch
	    {
		    $netSendResult = $Error[0].ToString()
		    echo "net send: $netSendResult"
	    }
	    finally
	    {
		    $ErrorActionPreference = $OldErrorActionPreference
	    }
	    
	    if ($netSendResult -match $SUCCESSFUL_MESSAGE)
	    {
	    }
	    else
	    {
		    $now = [DateTime]::Now
		    $msgBoxResult = [Windows.MessageBox]::Show( $now.ToString() + "`n`n" + $Message ,$caption)
	    }
    }
}