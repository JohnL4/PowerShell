<#
.SYNOPSIS
    Show heavy users of system resources without requiring a GUI like perfmon.
.NOTES
# (org-mode, http://orgmode.org/ )

Sadly, this thing is kind of hardcoded, at the moment, in terms of the columns and rows it displays.  But I think it's a
reasonable first guess.

* System counters that look interesting:

  - Memory
    - =\Memory\Page Faults/sec=
    - =\Memory\Available MBytes=
  - Network
    - =\IPv4\Datagrams/sec=
    - =\IPv6\Datagrams/sec=
    - =\TCPv4\Segments/sec=
    - =\TCPv6\Segments/sec=
    - =\Network Interface(*)\Bytes Total/sec=
    - =\Network Interface(*)\Current Bandwidth=
  - PhysicalDisk
    - =\PhysicalDisk(0 C:)\Avg. Disk Queue Length=
  - Process
    - =\Process(*)\ID Process= -- Process ID
    - =\Process(*)\% Processor Time=
    - =\Process(*)\Virtual Bytes=
    - =\Process(*)\Working Set=
    - =\Process(*)\Page Faults/sec=
    - =\Process(*)\IO Read Bytes/sec=
    - =\Process(*)\IO Write Bytes/sec=
    - =\Process(*)\IO Data Bytes/sec= -- This seems to cover both read and write of DATA
    - =\Process(*)\IO Other Bytes/sec= -- This seems to cover non-data (i.e., "command" or metadata) bytes
  - System
    - /(actually, doesn't look all that interesting -- no useful counters)/

* Invalid Counter Samples

  Sometimes you get this message:

  #+BEGIN_EXAMPLE
    Get-Counter : The data in one of the performance counter samples is not valid. View the Status property for each
    PerformanceCounterSample object to make sure it contains valid data.
  #+END_EXAMPLE

  See

  #+BEGIN_SRC powershell
    Get-Counter '\Process(*)\% Processor Time' -SampleInterval 1 -MaxSamples 2 `
            | select -exp countersamples `
            | ? {$_.status -eq 0} `
            | sort cookedvalue -desc `
            | select -first 10 `
            | select instancename,cookedvalue,rawvalue,status
  #+END_SRC 
     
* COMMENT Notes end
#>
param(
    [int]
    # Number of seconds to delay before resampling and redisplaying.
    $delay = 30,

    [int]
    # Number of processes to display in each section of the output
    $numProcesses = 8
    
    #
)

# See http://stackoverflow.com/a/12995867/370611
[System.Threading.Thread]::CurrentThread.Priority = 'BelowNormal'

$PROCESS_PATH_NAMES = 
    "\Process(*)\ID Process",
    "\Process(*)\% Processor Time",
    "\Process(*)\Virtual Bytes",
    "\Process(*)\Working Set",
    "\Process(*)\Page Faults/sec",
    "\Process(*)\IO Data Bytes/sec",
    "\Process(*)\IO Other Bytes/sec"

$SYS_PATH_NAME =
    "\Memory\Page Faults/sec",
    "\Memory\Available MBytes",
    "\Network Interface(*)\Bytes Total/sec",
    "\Network Interface(*)\Current Bandwidth",
    "\PhysicalDisk(*)\Avg. Disk Queue Length"

$ONE_MEG = 1000000 # 1024 * 1024

$NETWORK_INTERFACE_REGEX = New-Object Text.RegularExpressions.Regex "^network interface\((.*)\)"

$shortHeaders = @{
    CPU = "CPU";
    WorkingSet = "WS ";
    PageFaultsPerSec = "PF ";
    IOBytesPerSec = "IO "
    }

# For colorizing sorted column.  See usage of Write-PSObject, below.
$SORT_KEY_TO_COLUMN_HEADER_MAP = @{'CPU' = "CPU %"; 'WorkingSet' = "WS (MB)"; 'PageFaultsPerSec' = "PF/sec"; 'IOBytesPerSec' = "IO/sec (KB)"}

# Colorized table output, https://gallery.technet.microsoft.com/scriptcenter/Format-Table-Colors-in-e0a4beac
. $ProfileParent/Write-PSObject.ps1

# ---------------------------------------------------  Take-Sample  ----------------------------------------------------
<#
Takes one sample and dumps it to stdout as a series of calls to Format-Table (or Write-PSObject)
#>
function Take-Sample
{
    param(
        [int]
        # Delay in seconds
        $delay,

        [int]
        # Number of processes to display in each section of the output
        $numProcesses
        #
    )
    
    # Perf counter "paths" look like this:  "\\lusk-j-w71\process(chrome#12)\page faults/sec".

    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"

    $counterSamples = Get-Counter $counterPaths -SampleInterval $delay | select -expand CounterSamples

    # $sysCounterSamples = Get-Counter 

    $ErrorActionPreference = $oldErrorActionPreference

    # $counterSamples | gm

    Write-Verbose ("Got {0} counter samples" -f $counterSamples.Length)

    $counterObjects = New-Object System.Collections.ArrayList
    $specialCounters = New-Object Hashtable

    $counterHash = New-Object Hashtable
    # $counterHash['IO Bytes/sec'] = 0

    foreach ($counterSample in $counterSamples | sort Path)
    {
        $pathParts = ($counterSample.Path -split "\\")
        $n = $pathParts.Count
        $counterName = $pathParts[$n-1]
        $ProcessName = $pathParts[$n-2];              # Or 'IPv{4,6}' or 'Memory' or 'PhysicalDisk(something)'
        if (($counterHash.ProcessName -ne $Null) -and ($counterHash.ProcessName -ne $ProcessName))
        {
            # Write-Verbose ("new sample object for process {0}" -f $ProcessName)
            if (($counterHash.ProcessName -match '^Process\(') `
                    -and (-not (($counterHash.ProcessName -match '^Process\(_Total\)') `
                    -or ($counterHash.ProcessName -match '^Process\(Idle\)') `
                    )))
            {
                $addedAt = $counterObjects.Add( $($counterHash | New-HashObject))
            }
            else
            {
                # Not really a process name at this point, but whatever.
                $specialCounters[$counterHash.ProcessName] = $counterHash
            }
            $counterHash = New-Object Hashtable
            # $counterHash['IO Bytes/sec'] = 0
            #
        }
        $counterHash.ProcessName = $ProcessName
        switch ($counterName)
        {
            "ID Process" {
                $counterHash.ID = $counterSample.CookedValue
            }
            "% Processor Time" {
                $counterHash.CPU = $counterSample.CookedValue
            }
            "Virtual Bytes" {
                $counterHash.VirtualBytes = $counterSample.CookedValue
            }
            "Working Set" {
                $counterHash.WorkingSet = $counterSample.CookedValue
            }
            "Page Faults/sec" {                       # Also applies to '\Memory\' counters
                $counterHash.PageFaultsPerSec = $counterSample.CookedValue
            }
            "IO Data Bytes/sec" {
                $counterHash.IOBytesPerSec += $counterSample.CookedValue
            }
            "IO Other Bytes/sec" {
                $counterHash.IOBytesPerSec += $counterSample.CookedValue
            }
            default {
                $counterHash[$counterName] = $counterSample.CookedValue
            }
        }
        #
    }
    # last object
    $addedAt = $counterObjects.Add( $($counterHash | New-HashObject))

    Write-Verbose ("{0} counter objects" -f $counterObjects.Count)

    Write-Host -foreground cyan $(Get-Date)
    
    # foreach ($sortKey in @('% Processor Time','Virtual Bytes','Working Set','Page Faults/sec','IO Data Bytes/sec'))
    foreach ($sortKey in @('CPU','WorkingSet','PageFaultsPerSec','IOBytesPerSec'))
    {
        $sortColumnHeader = $SORT_KEY_TO_COLUMN_HEADER_MAP[ $sortKey]
        # Write-Host -foreground cyan ("Sorting by {0}" -f $sortKey)
        $counterObjects `
                | sort $sortKey -desc `
                | select -f $numProcesses `
                | select -prop @(
                    @{Label=$shortHeaders[$sortKey]; Expression=" "},
                    @{Label="ProcID"; Expression={$_.ID}}, 
                    @{Label="CPU %"; Expression={[Math]::Round( $_.CPU)}} ,
                    @{Label="VM (MB)"; Expression={[Math]::Round( $_.VirtualBytes / $ONE_MEG)}} ,
                    @{Label="WS (MB)"; Expression={[Math]::Round( $_.WorkingSet / $ONE_MEG)}} ,
                    @{Label="PF/sec"; Expression={[Math]::Round( $_.PageFaultsPerSec)}} ,
                    @{Label="IO/sec (KB)"; Expression={[Math]::Round( $_.IOBytesPerSec / 1000)}} 
                    @{Label="Process Name"; Expression={($_.ProcessName -split '[()]')[1]}} ) `
                | Write-PSObject -ColoredColumns $sortColumnHeader -ColumnForeColor Yellow # ft -au -wr
        Write-Host # Blank line
    }

    # $specialCounters | ft -au -wr

    $overallSys = @{IdleCpu = [Math]::Round( $specialCounters["process(idle)"].CPU);
                    AvailMem = [Math]::Round( $specialCounters["memory"]["available mbytes"]);
                    PageFaultsPerSec = [Math]::Round( $specialCounters["memory"].PageFaultsPerSec);
                    DiskQueue_C = [Math]::Round( $specialCounters["physicaldisk(0 c:)"]["avg. disk queue length"], 2)}
                    # IPv4_DgramsPerSec = [Math]::Round( $specialCounters["ipv4"]["datagrams/sec"]);
                    # IPv6_DgramsPerSec = [Math]::Round( $specialCounters["ipv6"]["datagrams/sec"])}

    # $networkInterfaceBytes = New-Object Collections.ArrayList
    $ethernetBytes = 0;
    $wifiBytes = 0;
    $otherBytes = 0;
    foreach ($counterKey in $specialCounters.Keys)
    {
        $match = $NETWORK_INTERFACE_REGEX.Match( $counterKey)
        $bps = $specialCounters[ $counterKey]["bytes total/sec"]
        if ($match.Success -and ($bps -gt 0))
        {
            $interface = $match.Groups[1]
            $bps = [Math]::Round( $bps)
            Write-Verbose ("interface {0} bytes/sec: {1}" -f $interface,$bps)
            # $addedAt = $networkInterfaceBytes.Add(
            #     $(@{Interface=$interface; "BytesPerSec" = [Math]::Round( $bps)} | New-HashObject))
            switch -regex ($interface)
            {
                "ethernet" { $ethernetBytes += $bps; Break }
                "wireless" { $wifiBytes += $bps; Break }
                default { $otherBytes += $bps }
            }
            #
        }
        #
    }

    # $networkInterfaceBytes | sort "Bytes/sec" -desc | ft -au

    $overallSys | New-HashObject `
            | select @(@{Label="Idle CPU %"; Expression="IdleCpu"}
                       ,@{Label="Avail MBytes"; Expression="AvailMem"}
                       ,@{Label="Page Faults/sec"; Expression="PageFaultsPerSec"}
                       ,@{Label="C: Queue Length"; Expression="DiskQueue_C"}
                       ,@{Label="Ethernet Bytes/sec"; Expression={$ethernetBytes}}
                       ,@{Label="Wifi Bytes/sec"; Expression={$wifiBytes}}
                       ,@{Label="Other Bytes/sec"; Expression={$otherBytes}}) `
                               | Write-PSObject # ft -auto

}

# ===================================================  MAIN BEGINS  ====================================================

$counterPaths = $PROCESS_PATH_NAMES + $SYS_PATH_NAME
Write-Verbose ("Will sample {0} counters, displaying {2} processes at an interval of {1} seconds" -f $counterPaths.Count,$delay,$numProcesses)

while ($True) {
    Take-Sample -delay $delay -numProcesses $numProcesses
}

# ====================================================  MAIN ENDS  =====================================================

