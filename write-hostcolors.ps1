<#
.SYNOPSIS
   Writes text to host showing the different colors available.  (Host console window may have had its colors tweaked,
   for whatever reason.)
#>

$bgColors = "Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray",
            "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White" 
$fgColors = "Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray",
            "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White" 

$bgColorLabels =  "Blk", "DkBlu", "DkGrn", "DkCyn", "DkRed", "DkMag", "DkYel", "Gry", "DkGry", "Blu", "Grn", "Cyn",
                  "Red", "Mag", "Yel", "Wht"
$fgColorLabels =  "Blk", "DkBlu", "DkGrn", "DkCyn", "DkRed", "DkMag", "DkYel", "Gry", "DkGry", "Blu", "Grn", "Cyn",
                  "Red", "Mag", "Yel", "Wht"

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
$b = 0   # Background color index
$f = 0   # Foreground color index
foreach ($fgColor in $fgColors)
{
    $fgColorLabel = $fgColorLabels[$f]
    $padLeft = [Math]::Floor( ($cellWidth - $fgColorLabel.Length) / 2)
    $padRight = $cellWidth - $padLeft - $fgColorLabel.Length
    Write-Debug "`$padLeft = $padLeft; `$padRight = $padRight"
    Write-Host $fgColorLabel.PadLeft( $cellWidth - $padRight).PadRight( $cellWidth) -nonewline
    $f++
}
Write-Host

$b = 0
foreach ($bgColor in $bgColors)
{
    $bgColorLabel = $bgColorLabels[$b]
    $padLeft = [Math]::Floor( ($cellWidth - $bgColorLabel.Length) / 2)
    $padRight = $cellWidth - $padLeft - $bgColorLabel.Length

    Write-Debug "`$padLeft = $padLeft; `$padRight = $padRight"
    Write-Host $bgColorLabel.PadLeft( $cellWidth - $padRight).PadRight( $cellWidth) -nonewline
    $f = 0
    foreach ($fgColor in $fgColors)
    {
        $fgColorLabel = $fgColorLabels[$f]
        $padLeft = [Math]::Floor( ($cellWidth - $fgColorLabel.Length) / 2)
        $padRight = $cellWidth - $padLeft - $fgColorLabel.Length

        Write-Debug "`$padLeft = $padLeft; `$padRight = $padRight"
        Write-Host $fgColorLabel.PadLeft( $cellWidth - $padRight).PadRight( $cellWidth) -nonewline -back $bgColor -fore $fgColor
        $f++
    }
    Write-Host
    $b++
}
