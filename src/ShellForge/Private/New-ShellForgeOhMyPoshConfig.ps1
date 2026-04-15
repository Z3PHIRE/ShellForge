Set-StrictMode -Version Latest

function New-ShellForgeOhMyPoshConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme
    )

    $configPath = Get-ShellForgePath -PathType 'OhMyPosh' -Ensure

    switch ($Theme.promptLayout.type) {
        'Glass' { $style = 'powerline' }
        'Grid' { $style = 'diamond' }
        'Boxed' { $style = 'diamond' }
        'Matrix' { $style = 'plain' }
        default { $style = 'powerline' }
    }

    $segments = [System.Collections.Generic.List[object]]::new()
    if ($Theme.segments.userEnabled) {
        [void]$segments.Add([pscustomobject]@{
            type       = 'session'
            style      = $style
            foreground = $Theme.palette.text
            background = $Theme.palette.surface
            template   = ' {{ .UserName }} '
        })
    }

    [void]$segments.Add([pscustomobject]@{
        type       = 'path'
        style      = $style
        foreground = $Theme.palette.accent
        background = $Theme.palette.background
        properties = [pscustomobject]@{
            style = if ($Theme.segments.pathMode -eq 'Full') { 'full' } else { 'folder' }
        }
        template   = ' {{ .Path }} '
    })

    if ($Theme.segments.gitEnabled) {
        [void]$segments.Add([pscustomobject]@{
            type       = 'git'
            style      = $style
            foreground = $Theme.palette.accentSecondary
            background = $Theme.palette.background
            template   = ' {{ .HEAD }}{{ if .Working.Changed }}*{{ end }} '
        })
    }

    $rightSegments = [System.Collections.Generic.List[object]]::new()
    if ($Theme.segments.executionTimeEnabled) {
        [void]$rightSegments.Add([pscustomobject]@{
            type       = 'executiontime'
            style      = 'plain'
            foreground = $Theme.palette.warning
            background = 'transparent'
            template   = ' {{ .FormattedMs }} '
        })
    }

    if ($Theme.segments.timeEnabled) {
        [void]$rightSegments.Add([pscustomobject]@{
            type       = 'time'
            style      = 'plain'
            foreground = $Theme.palette.muted
            background = 'transparent'
            template   = ' {{ .CurrentDate | date .Format }} '
            properties = [pscustomobject]@{
                format = '15:04:05'
            }
        })
    }

    $config = [pscustomobject]@{
        '$schema'   = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json'
        version     = 3
        final_space = $true
        blocks      = @(
            [pscustomobject]@{
                type      = 'prompt'
                alignment = 'left'
                segments  = @($segments)
            },
            [pscustomobject]@{
                type      = 'prompt'
                alignment = 'right'
                segments  = @($rightSegments)
            }
        )
    }

    Write-ShellForgeJsonFile -Path $configPath -Data $config -Depth 20
    return $configPath
}

