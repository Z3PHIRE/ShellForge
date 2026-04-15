Set-StrictMode -Version Latest

function Resolve-ShellForgeTheme {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'Path', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(ParameterSetName = 'Theme', Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [object]$Theme
    )

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Name' {
                $builtInThemePath = Get-ShellForgeBundledResourcePath -ResourceType 'Themes'
                $libraryThemePath = Get-ShellForgePath -PathType 'Themes' -Ensure
                $candidateFiles = @()
                if (Test-Path -LiteralPath $builtInThemePath) {
                    $candidateFiles += @(Get-ChildItem -LiteralPath $builtInThemePath -Filter '*.json' -File)
                }

                if (Test-Path -LiteralPath $libraryThemePath) {
                    $candidateFiles += @(Get-ChildItem -LiteralPath $libraryThemePath -Filter '*.json' -File)
                }

                foreach ($candidateFile in $candidateFiles) {
                    $candidateTheme = ConvertTo-ShellForgeThemeObject -InputObject $candidateFile.FullName
                    if ($candidateTheme.name -ieq $Name -or $candidateTheme.slug -ieq $Name -or $candidateFile.BaseName -ieq $Name) {
                        $themeObject = Assert-ShellForgeThemeObject -Theme $candidateTheme
                        return [pscustomobject]@{
                            Theme     = $themeObject
                            SourcePath = $candidateFile.FullName
                            SourceType = if ($candidateFile.DirectoryName -ieq $builtInThemePath) { 'BuiltIn' } else { 'Library' }
                        }
                    }
                }

                throw "ShellForge theme '$Name' was not found in built-in presets or the local library."
            }
            'Path' {
                $resolvedPath = [System.IO.Path]::GetFullPath($Path)
                $themeObject = Assert-ShellForgeThemeObject -Theme (ConvertTo-ShellForgeThemeObject -InputObject $resolvedPath)
                return [pscustomobject]@{
                    Theme      = $themeObject
                    SourcePath = $resolvedPath
                    SourceType = 'File'
                }
            }
            'Theme' {
                $themeObject = Assert-ShellForgeThemeObject -Theme (ConvertTo-ShellForgeThemeObject -InputObject $Theme)
                return [pscustomobject]@{
                    Theme      = $themeObject
                    SourcePath = ''
                    SourceType = 'Pipeline'
                }
            }
            default {
                throw 'Unsupported theme resolution mode.'
            }
        }
    }
}
