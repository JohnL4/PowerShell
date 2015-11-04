<#
.SYNOPSIS
   Shows a message in a dialog box.
.EXAMPLE
   Show-Message "hi there"
#>
function Show-Message
{
    param (
        [string]
        # The message you want to show
        $Message
        )

    # The following call is obsolete.  I'd like to find a better way to load this assembly without having to specify its
    # version exactly.  Although, who knows, maybe version 2.0.0.0 will be around forever.
    [Reflection.Assembly]::LoadWithPartialName( "System.Windows.Forms") | Out-Null

    $caption = "From PS @ " + $(get-location).ToString() + ":"

    [Windows.Forms.MessageBox]::Show($Message, $caption) | Out-Null
}
