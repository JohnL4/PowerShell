<#
.SYNOPSIS
   Wait for a host to wake up, as detected by Ping-Host.
#>
function waitfor
{
    param (
        [string]
        # The host to wait for
        $ComputerName
        )

    while (0 -eq $(Ping-Host $ComputerName -count 1).Received)
    {
        Start-Sleep -seconds 60
    }
    Write-Host
    Write-Host "$ComputerName is up." -Foreground cyan
    Write-Host
    xm "$ComputerName is up."
}
