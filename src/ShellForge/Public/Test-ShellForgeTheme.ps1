Set-StrictMode -Version Latest

function Test-ShellForgeTheme {
    <#
    .SYNOPSIS
    Validates a ShellForge theme object or theme file.
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    param(
        [Parameter(ParameterSetName = 'Path', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(ParameterSetName = 'Theme', Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [object]$Theme,

        [Parameter(ParameterSetName = 'All')]
        [switch]$All
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'All') {
            $validationResults = [System.Collections.Generic.List[object]]::new()
            foreach ($availableTheme in @(Get-ShellForgeTheme)) {
                try {
                    $resolvedTheme = Resolve-ShellForgeTheme -Path $availableTheme.SourcePath
                    [void]$validationResults.Add([pscustomobject]@{
                        IsValid   = $true
                        ThemeName = $resolvedTheme.Theme.name
                        Errors    = @()
                        Theme     = $resolvedTheme.Theme
                    })
                }
                catch {
                    [void]$validationResults.Add([pscustomobject]@{
                        IsValid   = $false
                        ThemeName = [string]$availableTheme.Name
                        Errors    = @($_.Exception.Message)
                        Theme     = $null
                    })
                }
            }

            return @($validationResults)
        }

        try {
            $resolvedTheme = if ($PSCmdlet.ParameterSetName -eq 'Path') {
                Resolve-ShellForgeTheme -Path $Path
            }
            else {
                Resolve-ShellForgeTheme -Theme $Theme
            }

            return [pscustomobject]@{
                IsValid   = $true
                ThemeName = $resolvedTheme.Theme.name
                Errors    = @()
                Theme     = $resolvedTheme.Theme
            }
        }
        catch {
            return [pscustomobject]@{
                IsValid   = $false
                ThemeName = if ($Theme -and $Theme.name) { [string]$Theme.name } else { '' }
                Errors    = @($_.Exception.Message)
                Theme     = $null
            }
        }
    }
}
