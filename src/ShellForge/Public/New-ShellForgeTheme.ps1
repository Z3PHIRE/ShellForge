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
        [ValidateSet('Subtle', 'Inline', 'Banner')]
        [string]$AdminWarningStyle = 'Inline',

        [Parameter(ParameterSetName = 'Template')]
        [ValidateSet('Palette', 'HighContrast', 'Calm', 'Neon')]
        [string]$SyntaxProfile = 'Palette',

        [Parameter(ParameterSetName = 'Template')]
        [ValidateSet('Block', 'Line', 'Underline')]
        [string]$CursorStyle = 'Line',

        [Parameter(ParameterSetName = 'Template')]
        [ValidateRange(10, 100)]
        [int]$OpacityPercent = 90,

        [Parameter(ParameterSetName = 'Template')]
        [string]$FontRecommendation = 'CaskaydiaCove Nerd Font',

        [Parameter(ParameterSetName = 'Template')]
        [bool]$GitEnabled = $true,

        [Parameter(ParameterSetName = 'Template')]
        [bool]$AdminEnabled = $true,

        [Parameter(ParameterSetName = 'Template')]
        [bool]$StatusEnabled = $true,

        [Parameter(ParameterSetName = 'Template')]
        [bool]$RuntimeEnabled = $true,

        [Parameter(ParameterSetName = 'Template')]
        [bool]$ExecutionTimeEnabled = $true,

        [Parameter(ParameterSetName = 'Template')]
        [bool]$BatteryEnabled = $false,

        [Parameter(ParameterSetName = 'Template')]
        [bool]$TimeEnabled = $true,

        [Parameter(ParameterSetName = 'Template')]
        [bool]$HostEnabled = $false,

        [Parameter(ParameterSetName = 'Template')]
        [bool]$UserEnabled = $false,

        [Parameter(ParameterSetName = 'Template')]
        [AllowEmptyString()]
        [string]$BackgroundHex = '',

        [Parameter(ParameterSetName = 'Template')]
        [AllowEmptyString()]
        [string]$PredictionColor = '',

        [Parameter(ParameterSetName = 'Template')]
        [AllowEmptyString()]
        [string]$SuccessColor = '',

        [Parameter(ParameterSetName = 'Template')]
        [AllowEmptyString()]
        [string]$ErrorColor = '',

        [Parameter(ParameterSetName = 'Template')]
        [switch]$Save
    )

    if ($PSCmdlet.ParameterSetName -eq 'Interactive') {
        return (Invoke-ShellForgeCustomBuilderMenu)
    }

    $theme = New-ShellForgeThemeTemplate `
        -Name $Name `
        -Description $Description `
        -PaletteName $PaletteName `
        -PromptStyle $PromptStyle `
        -Density $Density `
        -LineMode $LineMode `
        -IconDensity $IconDensity `
        -PathMode $PathMode `
        -AdminWarningStyle $AdminWarningStyle `
        -SyntaxProfile $SyntaxProfile `
        -CursorStyle $CursorStyle `
        -OpacityPercent $OpacityPercent `
        -FontRecommendation $FontRecommendation `
        -GitEnabled $GitEnabled `
        -AdminEnabled $AdminEnabled `
        -StatusEnabled $StatusEnabled `
        -RuntimeEnabled $RuntimeEnabled `
        -ExecutionTimeEnabled $ExecutionTimeEnabled `
        -BatteryEnabled $BatteryEnabled `
        -TimeEnabled $TimeEnabled `
        -HostEnabled $HostEnabled `
        -UserEnabled $UserEnabled `
        -BackgroundHex $BackgroundHex `
        -PredictionColor $PredictionColor `
        -SuccessColor $SuccessColor `
        -ErrorColor $ErrorColor

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
