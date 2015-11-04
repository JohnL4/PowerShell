<#
   .SYNOPSIS
      An alias for "Out-String -stream" for use at the interactive prompt.
   .DESCRIPTION
      Probably not the best thing to use in scripts because all its processing happens at the end
      (simulated 'end' clause by default in functions), which means it accumulates all its input
      until the end (possible large memory consumption for truly huge input streams).

      The assumption is that in interactive use, the input streams will be small, but if the input
      stream is large or you're writing a script, it's probably better to use "Out-String -stream"
      or the "os" alias.
#>
function oss
{
   $input | Out-String -stream
}
