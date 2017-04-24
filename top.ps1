<#
.SYNOPSIS
    Show heavy users of system resources (CPU, for now) without requiring a GUI like perfmon
.NOTES
# (org-mode, http://orgmode.org/ )
* System counters that look interesting:

  - IPv{4,6}
    - Datagrams/sec
  - Memory
    - Page Faults/sec
    - Available MBytes
  - PhysicalDisk
    - Avg. Disk Queue Length
  - Process
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

* Invalid CounterSamples

  Sometimes you get this message:

  #+BEGIN_EXAMPLE
    Get-Counter : The data in one of the performance counter samples is not valid. View the Status property for each
    PerformanceCounterSample object to make sure it contains valid data.
  #+END_EXAMPLE

  See

  #+BEGIN_SRC powershell
    Get-Counter '\Process(*)\% Processor Time' -SampleInterval 1 -MaxSamples 2 `
            | sel -exp countersamples `
            | ? {$_.status -eq 0} `
            | sort cookedvalue -desc `
            | sel -first 10 `
            | sel instancename,cookedvalue,rawvalue,status
  #+END_SRC 
     
* COMMENT Notes end
#>
param(
    [string]
    # The column on which to sort: c (cpu) or m (memory) or b (both)
    $sortColumn = "b",

    [int]
    # Number of seconds to delay before resampling and redisplaying.
    $delay = 15,

    [int]
    # Number of processes to display in each section of the output (see -sortColumn)
    $numProcesses = 15
    
    #
)

switch ($sortColumn[0])
{
    # Extra comma forces single-entry array to actually be arrays.
    "b" { $sortColumns = @("PctTime|CPU", "WorkingSet64")}
    "c" { $sortColumns = @("PctTime|CPU")}
    "m" { $sortColumns = @("WorkingSet64")}
    default { throw ("Unexpected sort column ({0}). Expected to be one of `"c`", `"m`"" -f $sortColumn)}
}
 
$processByPid = new-object HashTable

# Using SELECT to create a custom object that's a snapshot of the current object, otherwise we just get a POINTER to
# the current object, and trying to calculate time deltas always returns 0 (because we're always just subtracting the
# same value from itself).
#
# NOTE: 'SELECT *' == Bad.  Serious performance drag, for some reason.  Maybe iterating through a large number of
# properties, or maybe one or more of the properties iterated through is expensive to compute?
# 
ps | % {$processByPid[$_.Id] = $_ | select Id,ProcessName,CPU,WorkingSet64}

while ($True)
{
    sleep -seconds $delay
    # write-host "----------------------------------------------------------------"

    # Measure...
    
    # $totDelta = 0
    $procs = (ps | select -property ID,ProcessName,CPU,WorkingSet64,
            @{Name="PctTime";
              Expression={
                  if ($processByPid.ContainsKey( $_.Id))
                  {
                      $delta = $_.CPU - $processByPid[$_.Id].CPU
                  }
                  else
                  {
                      # Sloppy approximation; process must have started since the last sample
                      $delta = $_.CPU
                  }
                  $pctTime = $delta / $delay
                  # NOTE: for some reason, the following additions fails and always seems to restore $totDelta to 0
                  # before the computation.
                  #
                  # $totDelta = $totDelta + $delta
                  $processByPid[$_.Id] = $_ | select Id,ProcessName,CPU
                  $pctTime                        # Return value
              }})
    $stats = ($procs | Measure-Object PctTime,WorkingSet64 -sum).Sum
    $totPct = $stats[0]
    $totWS = $stats[1] / 1000000000
    # $stats += (gwmi Win32_OperatingSystem).FreePhysicalMemory
    $totFree = (gwmi Win32_OperatingSystem).FreePhysicalMemory / 1000000

    # Display...
    
    foreach ($sortSpec in $sortColumns)
    # for ($i = 0; $i -lt $sortColumns.Length; $i++)
    {
        # $sortSpec = $sortColumns[$i]
        $sortCols = $sortSpec -split "\|"         # -split defaults to regexp, so escape "|" in regexp terms
        Write-Verbose ("Sorting on {0} columns: {1}" -f $sortCols.Length,($sortCols -join ", "))
        $procs |
            sort -desc $sortCols |
            select -first $numProcesses Id,ProcessName,
                @{n="CPU";e={[Math]::Round( $_.CPU, 2)}},
                @{n="% Time";e={[Math]::Round( $_.PctTime * 100.0, 2)}},
                @{n="WS (MB)";e={[Math]::Round($_.WorkingSet64/1000000, 3)}} |
                ft -auto
    }
    Write-Host ("================ TOTAL CPU % = {0:P2}; Working Set = {1:N3} GB; Free Phys. Mem = {2:N3} GB" -f $totPct,$totWS,$totFree)
    #
}
