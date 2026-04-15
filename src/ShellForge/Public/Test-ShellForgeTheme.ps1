Set-StrictMode -Version Latest

function Test-ShellForgeTheme {
    <#
    .SYNOPSIS
    Validates a ShellForge theme object or theme file.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(ParameterSetName = 'Path', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(ParameterSetName = 'Theme', Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [object]$Theme
    )

    process {
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

