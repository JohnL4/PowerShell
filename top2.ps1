<#
.SYNOPSIS
    Show heavy users of system resources (CPU, for now) without requiring a GUI like perfmon
#>
param(
    [int]
    # Number of seconds to delay before resampling and redisplaying.
    $delay = 15
)

$counterSetNames = @("Memory", "Network Interface", "PhysicalDisk", "Process", "Processor")
$counterNames = @(
    "a",
    "b"
    )

(Get-Counter -List $counterSetNames).Paths | sort

