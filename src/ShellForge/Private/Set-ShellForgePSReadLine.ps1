Set-StrictMode -Version Latest

function Set-ShellForgePSReadLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme
    )

    $setPSReadLineCommand = Get-Command -Name Set-PSReadLineOption -ErrorAction SilentlyContinue
    if ($null -eq $setPSReadLineCommand) {
        Write-ShellForgeLog -Level 'WARN' -Operation 'PSReadLine' -Message 'PSReadLine is not available. Prompt rendering will continue without editor customization.'
        return
    }

    $colorTable = [ordered]@{
        Command            = $Theme.psReadLine.colors.Command
        Comment            = $Theme.psReadLine.colors.Comment
        Keyword            = $Theme.psReadLine.colors.Keyword
        String             = $Theme.psReadLine.colors.String
        Number             = $Theme.psReadLine.colors.Number
        Operator           = $Theme.psReadLine.colors.Operator
        Variable           = $Theme.psReadLine.colors.Variable
        Member             = $Theme.psReadLine.colors.Member
        Parameter          = $Theme.psReadLine.colors.Parameter
        Type               = $Theme.psReadLine.colors.Type
        Selection          = $Theme.psReadLine.colors.Selection
        InlinePrediction   = $Theme.psReadLine.colors.InlinePrediction
        Error              = $Theme.psReadLine.colors.Error
        ContinuationPrompt = $Theme.psReadLine.continuationPrompt
    }

    try {
        Set-PSReadLineOption -EditMode $Theme.psReadLine.editMode
    }
    catch {
        Write-ShellForgeLog -Level 'WARN' -Operation 'PSReadLine' -Message ("Unable to set PSReadLine edit mode '{0}'. {1}" -f $Theme.psReadLine.editMode, $_.Exception.Message)
    }

    foreach ($colorEntry in $colorTable.GetEnumerator()) {
        try {
            Set-PSReadLineOption -Colors @{ $colorEntry.Key = $colorEntry.Value }
        }
        catch {
            Write-ShellForgeLog -Level 'WARN' -Operation 'PSReadLine' -Message ("Skipping unsupported PSReadLine color '{0}'. {1}" -f $colorEntry.Key, $_.Exception.Message)
        }
    }
}
