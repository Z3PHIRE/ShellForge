Set-StrictMode -Version Latest

function New-ShellForgeTheme {
    <#
    .SYNOPSIS
    Creates a new ShellForge theme from the interactive builder or from explicit parameters.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Interactive')]
    param(
        [Parameter(ParameterSetName = 'Interactive')]
        [switch]$Interactive,

        [Parameter(ParameterSetName = 'Template', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'Template')]
        [string]$Description = 'Custom ShellForge theme',

        [Parameter(ParameterSetName = 'Template')]
        [ValidateSet('Cyber', 'Frost', 'Tactical', 'Neon', 'Nord', 'Amber', 'Purple', 'Graphite', 'Matrix')]
        [string]$PaletteName = 'Cyber',

        [Parameter(ParameterSetName = 'Template')]
        [ValidateSet('Glass', 'Minimal', 'Tactical', 'Grid', 'Nordic', 'SOC', 'Boxed', 'PathHeavy', 'Matrix', 'Custom')]
        [string]$PromptStyle = 'Custom',

        [Parameter(ParameterSetName = 'Template')]
        [ValidateSet('Low', 'Medium', 'High')]
        [string]$Density = 'Medium',

        [Parameter(ParameterSetName = 'Template')]
        [ValidateSet('SingleLine', 'DoubleLine')]
        [string]$LineMode = 'SingleLine',

        [Parameter(ParameterSetName = 'Template')]
        [ValidateSet('None', 'Low', 'Medium', 'High')]
        [string]$IconDensity = 'Medium',

        [Parameter(ParameterSetName = 'Template')]
        [ValidateSet('Leaf', 'Short', 'Full')]
        [string]$PathMode = 'Short',

        [Parameter(ParameterSetName = 'Template')]
        [switch]$Save
    )

    if ($PSCmdlet.ParameterSetName -eq 'Interactive') {
        return (Invoke-ShellForgeCustomBuilderMenu)
    }

    $theme = New-ShellForgeThemeTemplate -Name $Name -Description $Description -PaletteName $PaletteName -PromptStyle $PromptStyle -Density $Density -LineMode $LineMode -IconDensity $IconDensity -PathMode $PathMode
    if ($Save.IsPresent) {
        $savedPath = Join-Path -Path (Get-ShellForgePath -PathType 'Themes' -Ensure) -ChildPath ('{0}.json' -f $theme.slug)
        Write-ShellForgeJsonFile -Path $savedPath -Data $theme -Depth 20
        return [pscustomobject]@{
            Theme     = $theme
            SavedPath = $savedPath
        }
    }

    return $theme
}
