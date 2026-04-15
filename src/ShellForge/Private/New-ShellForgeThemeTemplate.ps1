Set-StrictMode -Version Latest

function New-ShellForgeThemeTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [string]$Description = 'Custom ShellForge theme',

        [Parameter()]
        [ValidateSet('Cyber', 'Frost', 'Tactical', 'Neon', 'Nord', 'Amber', 'Purple', 'Graphite', 'Matrix')]
        [string]$PaletteName = 'Cyber',

        [Parameter()]
        [ValidateSet('Glass', 'Minimal', 'Tactical', 'Grid', 'Nordic', 'SOC', 'Boxed', 'PathHeavy', 'Matrix', 'Custom')]
        [string]$PromptStyle = 'Custom',

        [Parameter()]
        [ValidateSet('Low', 'Medium', 'High')]
        [string]$Density = 'Medium',

        [Parameter()]
        [ValidateSet('SingleLine', 'DoubleLine')]
        [string]$LineMode = 'SingleLine',

        [Parameter()]
        [ValidateSet('None', 'Low', 'Medium', 'High')]
        [string]$IconDensity = 'Medium',

        [Parameter()]
        [ValidateSet('Leaf', 'Short', 'Full')]
        [string]$PathMode = 'Short',

        [Parameter()]
        [ValidateSet('Subtle', 'Inline', 'Banner')]
        [string]$AdminWarningStyle = 'Inline',

        [Parameter()]
        [ValidateSet('Palette', 'HighContrast', 'Calm', 'Neon')]
        [string]$SyntaxProfile = 'Palette',

        [Parameter()]
        [ValidateSet('Block', 'Line', 'Underline')]
        [string]$CursorStyle = 'Line',

        [Parameter()]
        [ValidateRange(10, 100)]
        [int]$OpacityPercent = 90,

        [Parameter()]
        [string]$FontRecommendation = 'CaskaydiaCove Nerd Font',

        [Parameter()]
        [bool]$GitEnabled = $true,

        [Parameter()]
        [bool]$AdminEnabled = $true,

        [Parameter()]
        [bool]$StatusEnabled = $true,

        [Parameter()]
        [bool]$RuntimeEnabled = $true,

        [Parameter()]
        [bool]$ExecutionTimeEnabled = $true,

        [Parameter()]
        [bool]$BatteryEnabled = $false,

        [Parameter()]
        [bool]$TimeEnabled = $true,

        [Parameter()]
        [bool]$HostEnabled = $false,

        [Parameter()]
        [bool]$UserEnabled = $false,

        [Parameter()]
        [string]$BackgroundHex = '',

        [Parameter()]
        [string]$PredictionColor = '',

        [Parameter()]
        [string]$SuccessColor = '',

        [Parameter()]
        [string]$ErrorColor = ''
    )

    switch ($PaletteName) {
        'Cyber' {
            $palette = [pscustomobject]@{
                background      = '#081421'
                surface         = '#112033'
                accent          = '#4DD0E1'
                accentSecondary = '#8875FF'
                text            = '#E8F7FF'
                muted           = '#7B9BB7'
                success         = '#2EE6A6'
                warning         = '#F4B95D'
                error           = '#FF5D7A'
                info            = '#7FD8FF'
            }
        }
        'Frost' {
            $palette = [pscustomobject]@{
                background      = '#0B1420'
                surface         = '#132132'
                accent          = '#A9D9FF'
                accentSecondary = '#7DB7FF'
                text            = '#F3F8FC'
                muted           = '#96AEC8'
                success         = '#7BDCB5'
                warning         = '#E8C36A'
                error           = '#FF7A8A'
                info            = '#BDE7FF'
            }
        }
        'Tactical' {
            $palette = [pscustomobject]@{
                background      = '#121212'
                surface         = '#232323'
                accent          = '#B24141'
                accentSecondary = '#E8C39E'
                text            = '#F6EFE6'
                muted           = '#9B9187'
                success         = '#6FD8A1'
                warning         = '#E7A15C'
                error           = '#ED5C5C'
                info            = '#C5B190'
            }
        }
        'Neon' {
            $palette = [pscustomobject]@{
                background      = '#111319'
                surface         = '#1D232E'
                accent          = '#19F0FF'
                accentSecondary = '#FF4FD8'
                text            = '#EAF9FF'
                muted           = '#8295AD'
                success         = '#59F7B2'
                warning         = '#FFC857'
                error           = '#FF5A7D'
                info            = '#84EFFF'
            }
        }
        'Nord' {
            $palette = [pscustomobject]@{
                background      = '#1B2330'
                surface         = '#253142'
                accent          = '#81A1C1'
                accentSecondary = '#88C0D0'
                text            = '#E5EDF5'
                muted           = '#94A7BA'
                success         = '#A3D5A8'
                warning         = '#EBCB8B'
                error           = '#BF616A'
                info            = '#8FBCBB'
            }
        }
        'Amber' {
            $palette = [pscustomobject]@{
                background      = '#0F0F0F'
                surface         = '#1C1C1C'
                accent          = '#FFB347'
                accentSecondary = '#FF8C42'
                text            = '#FFF3E0'
                muted           = '#AA977F'
                success         = '#FFCF6B'
                warning         = '#FF9F1C'
                error           = '#FF6B50'
                info            = '#FFD38A'
            }
        }
        'Purple' {
            $palette = [pscustomobject]@{
                background      = '#0C0B10'
                surface         = '#201A2C'
                accent          = '#9A6BFF'
                accentSecondary = '#D0A6FF'
                text            = '#F4EEFF'
                muted           = '#A69BC0'
                success         = '#6EF0B7'
                warning         = '#D9A0FF'
                error           = '#FF6FA7'
                info            = '#BBA7FF'
            }
        }
        'Graphite' {
            $palette = [pscustomobject]@{
                background      = '#161B1F'
                surface         = '#242C31'
                accent          = '#43B3AE'
                accentSecondary = '#C0CCD2'
                text            = '#F0F4F6'
                muted           = '#95A5AD'
                success         = '#6CD3B8'
                warning         = '#F0B15A'
                error           = '#FF7A7A'
                info            = '#6CCCD1'
            }
        }
        'Matrix' {
            $palette = [pscustomobject]@{
                background      = '#060B06'
                surface         = '#0B160B'
                accent          = '#5CFF7D'
                accentSecondary = '#88D96B'
                text            = '#D9FFD6'
                muted           = '#6C9C66'
                success         = '#6DF08D'
                warning         = '#A8F25D'
                error           = '#E86262'
                info            = '#95FF9B'
            }
        }
        default {
            throw "Unsupported palette '$PaletteName'."
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($BackgroundHex)) {
        if (-not (Test-ShellForgeHexColor -Value $BackgroundHex)) {
            throw "Background override '$BackgroundHex' is not a valid hex color."
        }

        $palette.background = $BackgroundHex
    }

    if ([string]::IsNullOrWhiteSpace($PredictionColor)) {
        $PredictionColor = $palette.muted
    }
    elseif (-not (Test-ShellForgeHexColor -Value $PredictionColor)) {
        throw "Prediction color '$PredictionColor' is not a valid hex color."
    }

    if ([string]::IsNullOrWhiteSpace($SuccessColor)) {
        $SuccessColor = $palette.success
    }
    elseif (-not (Test-ShellForgeHexColor -Value $SuccessColor)) {
        throw "Success color '$SuccessColor' is not a valid hex color."
    }

    if ([string]::IsNullOrWhiteSpace($ErrorColor)) {
        $ErrorColor = $palette.error
    }
    elseif (-not (Test-ShellForgeHexColor -Value $ErrorColor)) {
        throw "Error color '$ErrorColor' is not a valid hex color."
    }

    switch ($SyntaxProfile) {
        'Palette' {
            $psReadLineColors = [pscustomobject]@{
                Command          = $palette.accent
                Comment          = $palette.muted
                Keyword          = $palette.accentSecondary
                String           = $palette.text
                Number           = $palette.warning
                Operator         = $palette.text
                Variable         = $palette.info
                Member           = $palette.accentSecondary
                Parameter        = $palette.accent
                Type             = $palette.warning
                Selection        = $palette.surface
                InlinePrediction = $PredictionColor
                Error            = $ErrorColor
            }
        }
        'HighContrast' {
            $psReadLineColors = [pscustomobject]@{
                Command          = '#FFFFFF'
                Comment          = $palette.muted
                Keyword          = $palette.accent
                String           = '#E7FFF6'
                Number           = $palette.warning
                Operator         = '#FFFFFF'
                Variable         = $palette.info
                Member           = $palette.accentSecondary
                Parameter        = $palette.warning
                Type             = '#D2E4FF'
                Selection        = $palette.surface
                InlinePrediction = $PredictionColor
                Error            = $ErrorColor
            }
        }
        'Calm' {
            $psReadLineColors = [pscustomobject]@{
                Command          = $palette.text
                Comment          = $palette.muted
                Keyword          = $palette.accentSecondary
                String           = '#DCECF4'
                Number           = $palette.warning
                Operator         = $palette.text
                Variable         = $palette.accent
                Member           = $palette.info
                Parameter        = $palette.accentSecondary
                Type             = $palette.accent
                Selection        = $palette.surface
                InlinePrediction = $PredictionColor
                Error            = $ErrorColor
            }
        }
        'Neon' {
            $psReadLineColors = [pscustomobject]@{
                Command          = $palette.accent
                Comment          = $palette.muted
                Keyword          = $palette.accentSecondary
                String           = '#DFFAFE'
                Number           = '#FDE68A'
                Operator         = $palette.text
                Variable         = '#A7F3D0'
                Member           = '#E9D5FF'
                Parameter        = $palette.accent
                Type             = '#93C5FD'
                Selection        = $palette.surface
                InlinePrediction = $PredictionColor
                Error            = $ErrorColor
            }
        }
        default {
            throw "Unsupported syntax profile '$SyntaxProfile'."
        }
    }

    $promptSymbol = switch ($PromptStyle) {
        'Glass' { '>>' }
        'Minimal' { '>' }
        'Tactical' { '#>' }
        'Grid' { '::' }
        'Nordic' { '>' }
        'SOC' { '>>' }
        'Boxed' { '=>' }
        'PathHeavy' { '>>' }
        'Matrix' { '::' }
        default { '>>' }
    }

    $separatorStyle = switch ($PromptStyle) {
        'Glass' { 'Sharp' }
        'Minimal' { 'Clean' }
        'Tactical' { 'StatusFirst' }
        'Grid' { 'Dense' }
        'Nordic' { 'Calm' }
        'SOC' { 'Operational' }
        'Boxed' { 'Boxed' }
        'PathHeavy' { 'PathFirst' }
        'Matrix' { 'Retro' }
        default { 'Custom' }
    }

    $slug = ($Name.ToLowerInvariant() -replace '[^a-z0-9]+', '-') -replace '(^-)|(-$)', ''
    $theme = [pscustomobject]@{
        schemaVersion = '1.0'
        name          = $Name
        slug          = $slug
        description   = $Description
        intent        = 'Custom-built ShellForge workflow tailored through the numeric builder.'
        promptLayout  = [pscustomobject]@{
            type              = $PromptStyle
            density           = $Density
            lineMode          = $LineMode
            separatorStyle    = $separatorStyle
            promptSymbol      = $promptSymbol
            adminWarningStyle = $AdminWarningStyle
        }
        palette       = [pscustomobject]@{
            background      = $palette.background
            surface         = $palette.surface
            accent          = $palette.accent
            accentSecondary = $palette.accentSecondary
            text            = $palette.text
            muted           = $palette.muted
            success         = $SuccessColor
            warning         = $palette.warning
            error           = $ErrorColor
            info            = $palette.info
        }
        segments      = [pscustomobject]@{
            gitEnabled           = $GitEnabled
            adminEnabled         = $AdminEnabled
            statusEnabled        = $StatusEnabled
            runtimeEnabled       = $RuntimeEnabled
            executionTimeEnabled = $ExecutionTimeEnabled
            batteryEnabled       = $BatteryEnabled
            timeEnabled          = $TimeEnabled
            hostEnabled          = $HostEnabled
            userEnabled          = $UserEnabled
            pathMode             = $PathMode
        }
        iconDensity   = $IconDensity
        psReadLine    = [pscustomobject]@{
            editMode           = 'Windows'
            predictionColor    = $PredictionColor
            continuationPrompt = $palette.muted
            colors             = $psReadLineColors
        }
        terminal      = [pscustomobject]@{
            backgroundHex      = $palette.background
            opacityPercent     = $OpacityPercent
            cursorStyle        = $CursorStyle
            fontRecommendation = $FontRecommendation
        }
        compatibility = [pscustomobject]@{
            nativePromptSupported    = $true
            ohMyPoshProfileAvailable = $true
            minimumPowerShell        = '5.1'
            notes                    = @(
                'Native ShellForge prompt renderer works without external dependencies.',
                'Optional Oh My Posh configuration can be generated during installation.'
            )
        }
        preview       = [pscustomobject]@{
            sampleCommand = 'Get-ChildItem -Force'
            promptExample = '{0} shell session preview' -f $Name
        }
    }

    return (Assert-ShellForgeThemeObject -Theme $theme)
}
