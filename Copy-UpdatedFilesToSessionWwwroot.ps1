<#
.SYNOPSIS
    Copy recently-updated files to the wwwroot of a remote session to another machine

.DESCRIPTION
    Certain files will be excluded: 

    - Files below the .git directory
    - Temporary files (by the following regular expressions: ~$, ^#.*#$, ^\.#)

.NOTES
    Note that merely pushing recent files in a subdirectory still might not give the results you
    expect if your "new" subdirectory contains a bunch of old files (such as images) that are
    required to travel with the updated files.  In that case, it's probably better to just copy the
    entire directory.

.EXAMPLE

    cp $dirToPush (join-path "c:\inetpub\wwwroot" $($dirToPush.FullName | split-path -noq | split-path -parent)) -ToSession $vm  -rec -for -excl "*~" 

    Copy an entire directory tree, regardless of age.

#>
param (
    # The directory to mirror.  Can be either a string or a System.IO.FileSystemInfo object.
    $srcDir = ".",

    [String]
    # Destination directory to which to push to.
    $destDir = "C:\Inetpub\wwwroot",

    [int]
    # Age in minutes of files to be pushed.  Files older than this will not be pushed.
    $age = 10,

    [int]
    # Size limit in MB of files to be pushed.  Files over this limit will not be pushed, regardless of age.
    $sizeLimit = 10,

    [String]
    # Name of the host to which to push
    $hostname,

    [Management.Automation.Runspaces.PSSession]
    # Already-established remote session.  Probably more efficient than string hostname
    $session
)

$errors = $false

$dirToPush = (Get-Item $srcDir)
$maxLength = $sizeLimit * 1e6

if (("" -eq $hostname) -and ($Null -eq $session)) {
    Write-Error "One of -hostname or -session is required"
    $errors = $true
}
elseif ($hostname -ne "") {
    $vm = New-PSSession $hostname
}
else {
    $vm = $session
}

if ($errors) {
    exit
}

# ----------------------  BEGIN  ------------------------------------

pushd \

# List of string filenames relative to current directory.
$sentFiles = (ls $dirToPush -rec `
        | ? {$_.GetType() -eq [IO.FileInfo]} `
        | ? {-not ($_.FullName -match '/\.git/')} `
        | ? {-not ($_.Name -match '~$')} `
        | ? {-not ($_.Name -match '^#.*#$')} `
        | ? {-not ($_.Name -match '^\.#')} `
        | ? {$_.Length -le $maxLength} `
        | ? {$_.LastWriteTime -ge (Get-Date).AddMinutes( -$age)}  `
        | Resolve-Path -relative)

# Make directories to receive files on remote machine (sort | uniq to minimize mkdir commands)     
# Not sure why I can't pass a *list* of arguments to Invoke-Command, but oh well.   
$sentDirs = $sentFiles `
    | % {Split-Path -parent $_} `
    | sort `
    | Get-Unique `
    | % {Join-Path $destDir $_} `
    | % {Invoke-Command {param( $dir) mkdir -Path $dir -Force} -arg $_ -session $vm }

# Invoke-Command {param($dirs) mkdir -Force -Path $dirs} -arg $sentDirs -session $vm

$sentFiles `
    | % { cp $_ (join-path $destDir $_) -tosession $vm -for -pass}

echo $sentFiles

popd
