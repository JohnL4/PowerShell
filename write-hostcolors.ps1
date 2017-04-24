<#
.SYNOPSIS
   Writes text to host showing the different colors available.  (Host console window may have had its colors tweaked,
   for whatever reason.)
#>

$bgColors = "Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray",
            "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White" 
$fgColors = "Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray",
            "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White" 

if ($Host.UI.RawUI.WindowSize.Width -eq $Null) 
{ 
    $width = 200 
}
else 
{ 
    $width = $Host.UI.RawUI.WindowSize.Width - 1 
}

$cellWidth = [Math]::Floor( $width / ($fgColors.Length + 1))

$padLeft = [Math]::Floor( ($cellWidth - "BG\FG".Length) / 2)
$padRight = $cellWidth - $padLeft - "BG\FG".Length

Write-Debug "`$width = $width; `$cellWidth = $cellWidth; `$padLeft = $padLeft; `$padRight = $padRight"

Write-Host "BG\FG".PadLeft( $cellWidth - $padRight).PadRight( $cellWidth) -nonewline
foreach ($fgColor in $fgColors)
{
    $padLeft = [Math]::Floor( ($cellWidth - $fgColor.Length) / 2)
    $padRight = $cellWidth - $padLeft - $fgColor.Length
    Write-Debug "`$padLeft = $padLeft; `$padRight = $padRight"
    Write-Host $fgColor.PadLeft( $cellWidth - $padRight).PadRight( $cellWidth) -nonewline
}
Write-Host

foreach ($bgColor in $bgColors)
{
    $padLeft = [Math]::Floor( ($cellWidth - $bgColor.Length) / 2)
    $padRight = $cellWidth - $padLeft - $bgColor.Length

    Write-Debug "`$padLeft = $padLeft; `$padRight = $padRight"
    Write-Host $bgColor.PadLeft( $cellWidth - $padRight).PadRight( $cellWidth) -nonewline

    foreach ($fgColor in $fgColors)
    {
        $padLeft = [Math]::Floor( ($cellWidth - $fgColor.Length) / 2)
        $padRight = $cellWidth - $padLeft - $fgColor.Length

        Write-Debug "`$padLeft = $padLeft; `$padRight = $padRight"
        Write-Host $fgColor.PadLeft( $cellWidth - $padRight).PadRight( $cellWidth) -nonewline -back $bgColor -fore $fgColor
    }
    Write-Host
}
