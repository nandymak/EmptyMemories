<#
.SYNOPSIS
Copies the currently selected text in the current file with colorization
.DESCRIPTION
Copies the currently selected text in the current file with colorization.
This allows for a user to paste colorized scripts into Word or Outlook
.EXAMPLE
Copy-Colored 
#>

function Copy-Colorized ()
{
    if (-not $psISE.CurrentFile)
    {
        return
    }
    
    function Colorize
    {
        # colorize a script file or function

        param([string]$Text, [int]$Start = -1, [int]$End = -1)
        trap { break }
        $box = New-Object Windows.Forms.RichTextBox    
        $box.Font = New-Object Drawing.Font $psISE.Options.FontName, $psISE.Options.FontSize
        $box.Text = $Text

        # Now parse the text and report any errors...
        $parse_errs = $null
        $tokens = [System.Management.Automation.PSParser]::Tokenize($box.Text, [ref] $parse_errs)

        if ($parse_errs)
        {
            $parse_errs
            return
        }

        # iterate over the tokens an set the colors appropriately...
        foreach ($t in $tokens)
        {
            $box.Select($t.start, $t.length)
            $color = $psISE.Options.DefaultOptions.TokenColors[$t.Type]
            if ($color)
            {
                $box.selectioncolor = [Drawing.Color]::FromArgb($color.A, $color.R, $color.G, $color.B)
            }
        }
        if ($start -eq -1 -and $end -eq -1)
        {
            $box.Select(0,$box.Text.Length)
        }
        else
        {
            $box.Select($start, $end)
        }

        $box.Copy()
    }

    $editor = $psISE.CurrentFile.Editor
    $text = $editor.Text -replace '\r\n', "`n"
    if (-not $editor.SelectedText)
    {
        $selection = ($editor.Text -replace '\r\n', "`n")
    }
    else
    {
        $selection = ($editor.SelectedText -replace '\r\n', "`n")
    }

    Colorize $text $text.IndexOf(($selection -replace '\r\n', "`n")) $selection.Length
}
