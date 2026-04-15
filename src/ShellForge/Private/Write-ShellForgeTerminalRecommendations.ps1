Set-StrictMode -Version Latest

function Write-ShellForgeTerminalRecommendations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme
    )

    $recommendationPath = Get-ShellForgePath -PathType 'TerminalRecommendations' -Ensure
    $recommendation = [pscustomobject]@{
        generatedAt = [DateTimeOffset]::UtcNow.ToString('o')
        themeName   = $Theme.name
        themeSlug   = $Theme.slug
        terminal    = $Theme.terminal
        palette     = [pscustomobject]@{
            background = $Theme.palette.background
            surface    = $Theme.palette.surface
            accent     = $Theme.palette.accent
            text       = $Theme.palette.text
        }
    }

    Write-ShellForgeJsonFile -Path $recommendationPath -Data $recommendation
    return $recommendationPath
}

