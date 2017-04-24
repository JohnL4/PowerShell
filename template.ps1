<#
.SYNOPSIS
.DESCRIPTION
.PARAMETER <Parameter-Name>
.EXAMPLE
.INPUTS
.OUTPUTS
.NOTES
.LINK
   about_Comment_Based_Help
.LINK
   about_Functions
#>
function Verb-Noun
{
   param (
      [type] <# could be [switch] for boolean params #>
      # Documentation string
      $paramName1,
      [type]
      # Documentation string
      $paramName2,
      )

   begin { <# statement list -- Runs before pipeline processing starts #> }
   process { <# statement list -- Runs during pipeline processing, with $_ set to current object #> }
   end { <# statement list -- Runs after pipeline is processed.  This is the default if you leave begin/process/end out. #> }
}