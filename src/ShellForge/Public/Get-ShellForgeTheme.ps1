Set-StrictMode -Version Latest

function Get-ShellForgeTheme {
    <#
    .SYNOPSIS
    Returns ShellForge themes from built-in presets, the local library or the active configuration.
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'Path', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(ParameterSetName = 'Current', Mandatory)]
        [switch]$Current
    )

    switch ($PSCmdlet.ParameterSetName) {
        'Name' {
            $resolvedTheme = Resolve-ShellForgeTheme -Name $Name
            $theme = $resolvedTheme.Theme | Select-Object *
            $theme | Add-Member -NotePropertyName SourcePath -NotePropertyValue $resolvedTheme.SourcePath -Force
            $theme | Add-Member -NotePropertyName SourceType -NotePropertyValue $resolvedTheme.SourceType -Force
            return $theme
        }
        'Path' {
            $resolvedTheme = Resolve-ShellForgeTheme -Path $Path
            $theme = $resolvedTheme.Theme | Select-Object *
            $theme | Add-Member -NotePropertyName SourcePath -NotePropertyValue $resolvedTheme.SourcePath -Force
            $theme | Add-Member -NotePropertyName SourceType -NotePropertyValue $resolvedTheme.SourceType -Force
            return $theme
        }
        'Current' {
            $currentThemePath = Get-ShellForgePath -PathType 'CurrentTheme'
            if (-not (Test-Path -LiteralPath $currentThemePath)) {
                throw 'No current ShellForge theme is installed.'
            }

            $resolvedTheme = Resolve-ShellForgeTheme -Path $currentThemePath
            $theme = $resolvedTheme.Theme | Select-Object *
            $theme | Add-Member -NotePropertyName SourcePath -NotePropertyValue $currentThemePath -Force
            $theme | Add-Member -NotePropertyName SourceType -NotePropertyValue 'Current' -Force
            return $theme
        }
        default {
            $themeDirectories = @(
                [pscustomobject]@{ Path = Get-ShellForgeBundledResourcePath -ResourceType 'Themes'; SourceType = 'BuiltIn' },
                [pscustomobject]@{ Path = Get-ShellForgePath -PathType 'Themes' -Ensure; SourceType = 'Library' }
            )

            $themes = [System.Collections.Generic.List[object]]::new()
            foreach ($themeDirectory in $themeDirectories) {
                if (-not (Test-Path -LiteralPath $themeDirectory.Path)) {
                    continue
                }

                foreach ($themeFile in (Get-ChildItem -LiteralPath $themeDirectory.Path -Filter '*.json' -File | Sort-Object -Property BaseName)) {
                    $resolvedTheme = Resolve-ShellForgeTheme -Path $themeFile.FullName
                    $theme = $resolvedTheme.Theme | Select-Object *
                    $theme | Add-Member -NotePropertyName SourcePath -NotePropertyValue $resolvedTheme.SourcePath -Force
                    $theme | Add-Member -NotePropertyName SourceType -NotePropertyValue $themeDirectory.SourceType -Force
                    [void]$themes.Add($theme)
                }
            }

            return @($themes)
        }
    }
}

