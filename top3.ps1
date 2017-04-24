<#
.SYNOPSIS
    Show heavy users of system resources (CPU, for now) without requiring a GUI like perfmon
.NOTES
# (org-mode, http://orgmode.org/ )
* System counters that look interesting:

  - IPv{4,6}
    - =\IPv4\Datagrams/sec=
    - =\IPv6\Datagrams/sec=
  - Memory
    - =\Memory\Page Faults/sec=
    - =\Memory\Available MBytes=
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
    $delay = 15,

    [int]
    # Number of processes to display in each section of the output
    $numProcesses = 15
    
    #
)

$PROCESS_PATH_NAMES = 
    "\Process(*)\ID Process",
    "\Process(*)\% Processor Time",
    "\Process(*)\Virtual Bytes",
    "\Process(*)\Working Set",
    "\Process(*)\Page Faults/sec",
    "\Process(*)\IO Data Bytes/sec",
    "\Process(*)\IO Other Bytes/sec"

$SYS_PATH_NAME =
    "\IPv4\Datagrams/sec",
    "\IPv6\Datagrams/sec",
    "\Memory\Page Faults/sec",
    "\Memory\Available MBytes",
    "\PhysicalDisk(*)\Avg. Disk Queue Length"

$ONE_MEG = 1024 * 1024

# ---------------------------------------------------  Take-Sample  ----------------------------------------------------
<#
Takes one sample and dumps it to stdout as a series of calls to Format-Table
#>
function Take-Sample
{
    param(
        # Delay in seconds
        $delay
    )
    
    # Perf counter "paths" look like this:  "\\lusk-j-w71\process(chrome#12)\page faults/sec".

    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"

    $counterSamples = Get-Counter $counterPaths -SampleInterval $delay | select -expand CounterSamples

    $sysCounterSamples = Get-Counter 

    $ErrorActionPreference = $oldErrorActionPreference

    # $counterSamples | gm

    Write-Verbose ("Got {0} counter samples" -f $counterSamples.Length)

    $counterObjects = New-Object System.Collections.ArrayList
    $specialCounters = New-Object Hashtable

    $counterObject = New-Object Hashtable
    $counterObject['IO Bytes/sec'] = 0

    foreach ($counterSample in $counterSamples | sort Path)
    {
        $pathParts = ($counterSample.Path -split "\\")
        $n = $pathParts.Count
        $counterName = $pathParts[$n-1]
        $ProcessName = $pathParts[$n-2];              # Or 'IPv{4,6}' or 'Memory' or 'PhysicalDisk(something)'
        if (($counterObject.ProcessName -ne $Null) -and ($counterObject.ProcessName -ne $ProcessName))
        {
            # Write-Verbose ("new sample object for process {0}" -f $ProcessName)
            if (($counterObject.ProcessName -match '^Process\(') `
                    -and (-not (($counterObject.ProcessName -match '^Process\(_Total\)') `
                    -or ($counterObject.ProcessName -match '^Process\(Idle\)') `
                    )))
            {
                $addedAt = $counterObjects.Add( $($counterObject | New-HashObject))
            }
            else
            {
                # Not really a process name at this point, but whatever.
                $specialCounters[$counterObject.ProcessName] = $counterObject
            }
            $counterObject = New-Object Hashtable
            $counterObject['IO Bytes/sec'] = 0
            #
        }
        $counterObject.ProcessName = $ProcessName
        switch ($counterName)
        {
            "ID Process" {
                $counterObject.ID = $counterSample.CookedValue
            }
            "% Processor Time" {
                $counterObject.CPU = $counterSample.CookedValue
            }
            "Virtual Bytes" {
                $counterObject.VirtualBytes = $counterSample.CookedValue
            }
            "Working Set" {
                $counterObject.WorkingSet = $counterSample.CookedValue
            }
            "Page Faults/sec" {                       # Also applies to '\Memory\' counters
                $counterObject.PageFaultsPerSec = $counterSample.CookedValue
            }
            "IO Data Bytes/sec" {
                $counterObject.IOBytesPerSec += $counterSample.CookedValue
            }
            "IO Other Bytes/sec" {
                $counterObject.IOBytesPerSec += $counterSample.CookedValue
            }
            default {
                $counterObject[$counterName] = $counterSample.CookedValue
            }
        }
        #
    }
    # last object
    $addedAt = $counterObjects.Add( $($counterObject | New-HashObject))

    Write-Verbose ("{0} counter objects" -f $counterObjects.Count)

    # foreach ($sortKey in @('% Processor Time','Virtual Bytes','Working Set','Page Faults/sec','IO Data Bytes/sec'))
    foreach ($sortKey in @('CPU','PageFaultsPerSec','IOBytesPerSec'))
    {
        Write-Host -foreground cyan ("Sorting by {0}" -f $sortKey)
        $counterObjects `
                | sort $sortKey -desc `
                | select -f 7 `
                | select -prop @("ID" `
                ,@{Label="CPU %"; Expression={[Math]::Round( $_.CPU)}} `
                ,@{Label="VM (MiB)"; Expression={[Math]::Round( $_.VirtualBytes / $ONE_MEG)}} `
                ,@{Label="WS (MiB)"; Expression={[Math]::Round( $_.WorkingSet / $ONE_MEG)}} `
                ,@{Label="Pg Faults/sec"; Expression={[Math]::Round( $_.PageFaultsPerSec)}} `
                ,@{Label="IO/sec (Kib)"; Expression={[Math]::Round( $_.IOBytesPerSec / 1024)}} `
                ,@{Label="Process Name"; Expression={($_.ProcessName -split '[()]')[1]}} ) `
                | ft -au -wr
    }

    # $specialCounters | ft -au -wr

    $overallSys = @{IdleCpu = [Math]::Round( $specialCounters["process(idle)"].CPU);
                    AvailMem = [Math]::Round( $specialCounters["memory"]["available mbytes"]);
                    PageFaultsPerSec = [Math]::Round( $specialCounters["memory"].PageFaultsPerSec);
                    DiskQueue_C = [Math]::Round( $specialCounters["physicaldisk(0 c:)"]["avg. disk queue length"], 2);
                    IPv4_DgramsPerSec = [Math]::Round( $specialCounters["ipv4"]["datagrams/sec"]);
                    IPv6_DgramsPerSec = [Math]::Round( $specialCounters["ipv6"]["datagrams/sec"])}

    $overallSys | New-HashObject `
            | select @(@{Label="Idle CPU %"; Expression="IdleCpu"}
                       ,@{Label="Avail MBytes"; Expression="AvailMem"}
                       ,@{Label="Page Faults/sec"; Expression="PageFaultsPerSec"}
                       ,@{Label="C: Queue Length"; Expression="DiskQueue_C"}
                       ,@{Label="IPv4 Dgrams/sec"; Expression="IPv4_DgramsPerSec"}
                       ,@{Label="IPv6 Dgrams/sec"; Expression="IPv6_DgramsPerSec"}) `
                               | ft -auto
}

# ===================================================  MAIN BEGINS  ====================================================

$counterPaths = $PROCESS_PATH_NAMES + $SYS_PATH_NAME
Write-Verbose ("Will sample {0} counters at an interval of {1} seconds" -f $counterPaths.Count,$delay)

while ($True) {
    Take-Sample -delay $delay
}

# ====================================================  MAIN ENDS  =====================================================

