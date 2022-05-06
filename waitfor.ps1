<#
.SYNOPSIS
   Wait for a host to go away and then come back, as detected by Test-Connection.
.DESCRIPTION
   Start this script BEFORE rebooting the host in question, so there can be no doubt about the starting state (alive).
#>
function waitfor
{
    param (
        [string]
        # The host to wait for
        $ComputerName
        )

    # while (0 -eq $(Ping-Host $ComputerName -count 1).Received)
    $n = 1
    while (Test-Connection -Quiet $ComputerName -count 1)
    {
        Write-Host "`t$(Get-Date -uf '%H:%M:%S') -- $ComputerName still up ($n)"
        $n = $n + 1
        # More aggressive pinging while it's still up because we don't want it to go down and come back up w/in 60
        # seconds (which it could do, because it's probably a VM) so that we miss the "came back up" event.
        Start-Sleep -Seconds 3
    }
    Write-Host "`t$ComputerName has gone down"
    while (-not $(Test-Connection -quiet $ComputerName -count 1))
    {
        Write-Host "`t$(Get-Date -uf '%H:%M:%S') -- $ComputerName still down ($n)"
        $n = $n + 1
        Start-Sleep -seconds 60
    }
    Write-Host
    Write-Host "$ComputerName is up." -Foreground cyan
    Write-Host
    # xm "$ComputerName is up."
}
