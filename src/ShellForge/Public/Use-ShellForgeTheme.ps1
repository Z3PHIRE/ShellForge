Set-StrictMode -Version Latest

function Use-ShellForgeTheme {
    <#
    .SYNOPSIS
    Applies a ShellForge theme to the current interactive session without changing the user profile.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Interactive')]
    param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'Path', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(ParameterSetName = 'Theme', Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [object]$Theme,

        [Parameter(ParameterSetName = 'Interactive')]
        [switch]$Interactive
    )

    process {
        $resolvedTheme = switch ($PSCmdlet.ParameterSetName) {
            'Name' { Resolve-ShellForgeTheme -Name $Name }
            'Path' { Resolve-ShellForgeTheme -Path $Path }
            'Theme' { Resolve-ShellForgeTheme -Theme $Theme }
            'Interactive' {
                $selectedTheme = Select-ShellForgeTheme -Title 'SHELLFORGE' -Subtitle 'Apply a theme to the current session'
                if ($null -eq $selectedTheme) {
                    return $null
                }

                $selectedTheme
            }
        }

        if ($PSCmdlet.ShouldProcess($resolvedTheme.Theme.name, 'Apply ShellForge theme to current session')) {
            $script:ShellForgeCurrentTheme = $resolvedTheme.Theme
            Set-ShellForgePSReadLine -Theme $resolvedTheme.Theme
            Set-ShellForgePrompt
            Write-ShellForgeLog -Level 'ACTION' -Operation 'UseTheme' -Message ("Applied theme '{0}' to the current session." -f $resolvedTheme.Theme.name)
            return $resolvedTheme.Theme
        }
    }
}
