Set-StrictMode -Version Latest

# Internal layout helpers ----------------------------------------------------

function Get-ShellForgeConsoleWidth {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateRange(40, 120)]
        [int]$DefaultWidth = 64,

        [Parameter()]
        [ValidateRange(40, 120)]
        [int]$MaxWidth = 82
    )

    try {
        if (-not [Console]::IsOutputRedirected) {
            $consoleWidth = [Console]::WindowWidth
            if ($consoleWidth -gt 24) {
                return [Math]::Min($MaxWidth, [Math]::Max(40, $consoleWidth - 4))
            }
        }
    }
    catch {
    }

    return $DefaultWidth
}

function Get-ShellForgeUiGlyph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('LightHorizontal', 'HeavyHorizontal', 'DoubleHorizontal', 'DashedHorizontal', 'TopLeft', 'TopRight', 'BottomLeft', 'BottomRight', 'Vertical', 'LeftDivider', 'RightDivider', 'SectionBar', 'Diamond', 'Pointer', 'MiddleDot', 'Block', 'Check', 'Cross')]
        [string]$Name
    )

    switch ($Name) {
        'LightHorizontal' { return [string][char]0x2500 }
        'HeavyHorizontal' { return [string][char]0x2501 }
        'DoubleHorizontal' { return [string][char]0x2550 }
        'DashedHorizontal' { return [string][char]0x254C }
        'TopLeft' { return [string][char]0x2554 }
        'TopRight' { return [string][char]0x2557 }
        'BottomLeft' { return [string][char]0x255A }
        'BottomRight' { return [string][char]0x255D }
        'Vertical' { return [string][char]0x2551 }
        'LeftDivider' { return [string][char]0x2560 }
        'RightDivider' { return [string][char]0x2563 }
        'SectionBar' { return [string][char]0x258C }
        'Diamond' { return [string][char]0x25C6 }
        'Pointer' { return [string][char]0x25B8 }
        'MiddleDot' { return [string][char]0x00B7 }
        'Block' { return [string][char]0x2588 }
        'Check' { return [string][char]0x2713 }
        'Cross' { return [string][char]0x2717 }
        default { return '' }
    }
}

function Get-ShellForgeFittedText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory)]
        [ValidateRange(1, 200)]
        [int]$Width
    )

    if ($Text.Length -le $Width) {
        return $Text.PadRight($Width)
    }

    if ($Width -le 3) {
        return $Text.Substring(0, $Width)
    }

    return ($Text.Substring(0, $Width - 3) + '...')
}

function Write-ShellForgeDivider {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Light', 'Heavy', 'Double', 'Dash')]
        [string]$Style = 'Light',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$HexColor = '#1E3040'
    )

    $consoleWidth = Get-ShellForgeConsoleWidth
    $lineCharacter = switch ($Style) {
        'Heavy' { Get-ShellForgeUiGlyph -Name 'HeavyHorizontal' }
        'Double' { Get-ShellForgeUiGlyph -Name 'DoubleHorizontal' }
        'Dash' { Get-ShellForgeUiGlyph -Name 'DashedHorizontal' }
        default { Get-ShellForgeUiGlyph -Name 'LightHorizontal' }
    }

    $dividerText = $lineCharacter * $consoleWidth
    if (Test-ShellForgeVirtualTerminalSupport) {
        Write-Host (Get-ShellForgeAnsiText -Text $dividerText -HexColor $HexColor)
    }
    else {
        Write-Host $dividerText -ForegroundColor DarkGray
    }
}

function Write-ShellForgeSectionTitle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Title
    )

    Write-Host ''
    if (Test-ShellForgeVirtualTerminalSupport) {
        $prefix = Get-ShellForgeAnsiText -Text (Get-ShellForgeUiGlyph -Name 'SectionBar') -HexColor '#4DD0E1'
        $label = Get-ShellForgeAnsiText -Text (' ' + $Title.ToUpperInvariant()) -HexColor '#4DD0E1'
        Write-Host ('{0}{1}' -f $prefix, $label)
    }
    else {
        Write-Host (' - {0}' -f $Title.ToUpperInvariant()) -ForegroundColor Cyan
    }
}

function Get-ShellForgeThemeCategory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme
    )

    switch ([string]$Theme.promptLayout.type) {
        'Glass' { return 'Signature / Premium' }
        'Minimal' { return 'Signature / Premium' }
        'Boxed' { return 'Signature / Premium' }
        'Tactical' { return 'Operations / Response' }
        'SOC' { return 'Operations / Response' }
        'Nordic' { return 'Engineering / Daily' }
        'PathHeavy' { return 'Engineering / Daily' }
        'Grid' { return 'Developer / High Signal' }
        'Matrix' { return 'Developer / High Signal' }
        default { return 'Custom / Local' }
    }
}

function Get-ShellForgeThemeDescriptor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme
    )

    switch ([string]$Theme.Name) {
        'CyberGlass' { return 'Segmented cyber prompt with premium balance' }
        'Arctic Void' { return 'Calm, cold and ultra-readable minimal shell' }
        'Red Tactical' { return 'Failure-first layout tuned for operations work' }
        'Neon Grid' { return 'Dense developer signal with sharp neon contrast' }
        'Obsidian Nord' { return 'Composed engineering shell built around git flow' }
        'Amber SOC' { return 'Monitoring-first shell with warning visibility' }
        'Purple Forge' { return 'Expressive boxed prompt with strong identity' }
        'Graphite Pulse' { return 'Path-heavy daily shell with practical signal' }
        'Eclipse Matrix' { return 'Retro-modern terminal feel with readable status' }
        default { return [string]$Theme.description }
    }
}

function Get-ShellForgeThemeCoreSegments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme
    )

    $segmentItems = [System.Collections.Generic.List[string]]::new()
    [void]$segmentItems.Add(('path:{0}' -f $Theme.segments.pathMode.ToLowerInvariant()))
    if ($Theme.segments.gitEnabled) { [void]$segmentItems.Add('git') }
    if ($Theme.segments.statusEnabled) { [void]$segmentItems.Add('status') }
    if ($Theme.segments.adminEnabled) { [void]$segmentItems.Add('admin') }
    return ($segmentItems -join ('  ' + (Get-ShellForgeUiGlyph -Name 'MiddleDot') + '  '))
}

function Get-ShellForgeThemeContextSegments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme
    )

    $segmentItems = [System.Collections.Generic.List[string]]::new()
    if ($Theme.segments.runtimeEnabled) { [void]$segmentItems.Add('runtime') }
    if ($Theme.segments.executionTimeEnabled) { [void]$segmentItems.Add('exec') }
    if ($Theme.segments.timeEnabled) { [void]$segmentItems.Add('clock') }
    if ($Theme.segments.hostEnabled) { [void]$segmentItems.Add('host') }
    if ($Theme.segments.userEnabled) { [void]$segmentItems.Add('user') }
    if ($Theme.segments.batteryEnabled) { [void]$segmentItems.Add('battery') }

    if ($segmentItems.Count -eq 0) {
        return 'none'
    }

    return ($segmentItems -join ('  ' + (Get-ShellForgeUiGlyph -Name 'MiddleDot') + '  '))
}

function Get-ShellForgePalettePreviewText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme
    )

    if (-not (Test-ShellForgeVirtualTerminalSupport)) {
        return ('bg:{0}  accent:{1}  text:{2}  err:{3}' -f
            $Theme.palette.background,
            $Theme.palette.accent,
            $Theme.palette.text,
            $Theme.palette.error)
    }

    $blockPair = (Get-ShellForgeUiGlyph -Name 'Block') * 2
    $swatches = @(
        [pscustomobject]@{ Label = 'bg'; Color = [string]$Theme.palette.background },
        [pscustomobject]@{ Label = 'sf'; Color = [string]$Theme.palette.surface },
        [pscustomobject]@{ Label = 'ac'; Color = [string]$Theme.palette.accent },
        [pscustomobject]@{ Label = 'a2'; Color = [string]$Theme.palette.accentSecondary },
        [pscustomobject]@{ Label = 'tx'; Color = [string]$Theme.palette.text },
        [pscustomobject]@{ Label = 'mu'; Color = [string]$Theme.palette.muted },
        [pscustomobject]@{ Label = 'ok'; Color = [string]$Theme.palette.success },
        [pscustomobject]@{ Label = 'wa'; Color = [string]$Theme.palette.warning },
        [pscustomobject]@{ Label = 'er'; Color = [string]$Theme.palette.error }
    )

    $previewParts = [System.Collections.Generic.List[string]]::new()
    foreach ($swatch in $swatches) {
        $blockText = Get-ShellForgeAnsiText -Text $blockPair -HexColor $swatch.Color
        $labelText = Get-ShellForgeAnsiText -Text $swatch.Label -HexColor '#3A5060'
        [void]$previewParts.Add($blockText + $labelText)
    }

    return ($previewParts -join ' ')
}

function Show-ShellForgeHeader {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Title = 'SHELLFORGE',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Subtitle = 'PowerShell Theme Studio and Deployment Engine'
    )

    $shouldClearHost = $true
    try {
        if ([Console]::IsOutputRedirected -or [Console]::IsErrorRedirected) {
            $shouldClearHost = $false
        }
    }
    catch {
        $shouldClearHost = $true
    }

    if ($shouldClearHost) {
        try {
            Clear-Host -ErrorAction Stop
        }
        catch {
        }
    }

    $consoleWidth = Get-ShellForgeConsoleWidth
    $innerWidth = $consoleWidth - 2
    $defaultSubtitle = 'PowerShell Theme Studio and Deployment Engine'
    $middleDot = Get-ShellForgeUiGlyph -Name 'MiddleDot'
    $diamond = Get-ShellForgeUiGlyph -Name 'Diamond'
    $pointer = Get-ShellForgeUiGlyph -Name 'Pointer'

    if (Test-ShellForgeVirtualTerminalSupport) {
        $borderColor = '#16303F'
        $titleColor = '#E8F7FF'
        $taglineColor = '#3A5A6A'
        $accentColor = '#4DD0E1'

        $leftBorder = Get-ShellForgeAnsiText -Text (Get-ShellForgeUiGlyph -Name 'Vertical') -HexColor $borderColor
        $rightBorder = Get-ShellForgeAnsiText -Text (Get-ShellForgeUiGlyph -Name 'Vertical') -HexColor $borderColor
        $topBorder = (Get-ShellForgeUiGlyph -Name 'TopLeft') + ((Get-ShellForgeUiGlyph -Name 'DoubleHorizontal') * $innerWidth) + (Get-ShellForgeUiGlyph -Name 'TopRight')
        $bottomBorder = (Get-ShellForgeUiGlyph -Name 'BottomLeft') + ((Get-ShellForgeUiGlyph -Name 'DoubleHorizontal') * $innerWidth) + (Get-ShellForgeUiGlyph -Name 'BottomRight')

        Write-Host (Get-ShellForgeAnsiText -Text $topBorder -HexColor $borderColor)

        $titleRowContent = '  ' + $diamond + '  ' + $Title
        Write-Host ('{0}{1}{2}' -f
            $leftBorder,
            (Get-ShellForgeAnsiText -Text (Get-ShellForgeFittedText -Text $titleRowContent -Width $innerWidth) -HexColor $titleColor),
            $rightBorder)

        $taglineText = '  terminal theming  ' + $middleDot + '  prompt engine  ' + $middleDot + '  safe deployment'
        Write-Host ('{0}{1}{2}' -f
            $leftBorder,
            (Get-ShellForgeAnsiText -Text (Get-ShellForgeFittedText -Text $taglineText -Width $innerWidth) -HexColor $taglineColor),
            $rightBorder)

        if ($Subtitle -ne $defaultSubtitle) {
            $subtitleText = '  ' + $pointer + '  ' + $Subtitle
            Write-Host ('{0}{1}{2}' -f
                $leftBorder,
                (Get-ShellForgeAnsiText -Text (Get-ShellForgeFittedText -Text $subtitleText -Width $innerWidth) -HexColor $accentColor),
                $rightBorder)
        }

        Write-Host (Get-ShellForgeAnsiText -Text $bottomBorder -HexColor $borderColor)
    }
    else {
        $topBorder = (Get-ShellForgeUiGlyph -Name 'TopLeft') + ((Get-ShellForgeUiGlyph -Name 'DoubleHorizontal') * $innerWidth) + (Get-ShellForgeUiGlyph -Name 'TopRight')
        $bottomBorder = (Get-ShellForgeUiGlyph -Name 'BottomLeft') + ((Get-ShellForgeUiGlyph -Name 'DoubleHorizontal') * $innerWidth) + (Get-ShellForgeUiGlyph -Name 'BottomRight')
        $leftBorder = Get-ShellForgeUiGlyph -Name 'Vertical'
        $rightBorder = Get-ShellForgeUiGlyph -Name 'Vertical'

        Write-Host $topBorder -ForegroundColor DarkCyan
        Write-Host ('{0}{1}{2}' -f $leftBorder, (Get-ShellForgeFittedText -Text ('  *  ' + $Title) -Width $innerWidth), $rightBorder) -ForegroundColor White
        Write-Host ('{0}{1}{2}' -f $leftBorder, (Get-ShellForgeFittedText -Text '  terminal theming - prompt engine - safe deployment' -Width $innerWidth), $rightBorder) -ForegroundColor DarkGray
        if ($Subtitle -ne $defaultSubtitle) {
            Write-Host ('{0}{1}{2}' -f $leftBorder, (Get-ShellForgeFittedText -Text ('  >  ' + $Subtitle) -Width $innerWidth), $rightBorder) -ForegroundColor Gray
        }

        Write-Host $bottomBorder -ForegroundColor DarkCyan
    }

    Write-Host ''
}

function Show-ShellForgeThemePreview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme
    )

    $useAnsi = Test-ShellForgeVirtualTerminalSupport
    $consoleWidth = Get-ShellForgeConsoleWidth
    $innerWidth = $consoleWidth - 2
    $borderColor = '#16303F'
    $titleColor = '#E8F7FF'
    $valueColor = '#B0CCD8'
    $keyColor = '#3A5A6A'
    $accentColor = '#4DD0E1'
    $mutedColor = '#7B9BB7'
    $successColor = '#2EE6A6'
    $warningColor = '#F4B95D'
    $errorColor = '#FF5D7A'
    $lightHorizontal = Get-ShellForgeUiGlyph -Name 'LightHorizontal'
    $doubleHorizontal = Get-ShellForgeUiGlyph -Name 'DoubleHorizontal'
    $vertical = Get-ShellForgeUiGlyph -Name 'Vertical'
    $topBorderRaw = (Get-ShellForgeUiGlyph -Name 'TopLeft') + ($doubleHorizontal * $innerWidth) + (Get-ShellForgeUiGlyph -Name 'TopRight')
    $middleBorderRaw = (Get-ShellForgeUiGlyph -Name 'LeftDivider') + ($lightHorizontal * $innerWidth) + (Get-ShellForgeUiGlyph -Name 'RightDivider')
    $bottomBorderRaw = (Get-ShellForgeUiGlyph -Name 'BottomLeft') + ($doubleHorizontal * $innerWidth) + (Get-ShellForgeUiGlyph -Name 'BottomRight')
    $dividerText = '  ' + (Get-ShellForgeUiGlyph -Name 'MiddleDot') + '  '
    $descriptor = Get-ShellForgeThemeDescriptor -Theme $Theme
    $category = Get-ShellForgeThemeCategory -Theme $Theme
    $checkGlyph = Get-ShellForgeUiGlyph -Name 'Check'
    $crossGlyph = Get-ShellForgeUiGlyph -Name 'Cross'
    $diamond = Get-ShellForgeUiGlyph -Name 'Diamond'
    $pointer = Get-ShellForgeUiGlyph -Name 'Pointer'

    function Write-ShellForgeCardLine {
        param(
            [Parameter(Mandatory)]
            [AllowEmptyString()]
            [string]$RawText,

            [Parameter()]
            [AllowEmptyString()]
            [string]$StyledText = '',

            [Parameter()]
            [string]$FallbackColor = 'White'
        )

        $truncated = $RawText.Length -gt $innerWidth
        $displayRaw = Get-ShellForgeFittedText -Text $RawText -Width $innerWidth
        if ($useAnsi) {
            $contentText = $StyledText
            if ($truncated -or [string]::IsNullOrWhiteSpace($contentText)) {
                $contentText = Get-ShellForgeAnsiText -Text $displayRaw -HexColor $valueColor
            }
            else {
                $paddingWidth = $innerWidth - $RawText.Length
                if ($paddingWidth -lt 0) {
                    $paddingWidth = 0
                }

                $contentText = $contentText + (' ' * $paddingWidth)
            }

            $leftBorder = Get-ShellForgeAnsiText -Text $vertical -HexColor $borderColor
            $rightBorder = Get-ShellForgeAnsiText -Text $vertical -HexColor $borderColor
            Write-Host ('{0}{1}{2}' -f $leftBorder, $contentText, $rightBorder)
            return
        }

        Write-Host ('{0}{1}{2}' -f $vertical, $displayRaw, $vertical) -ForegroundColor $FallbackColor
    }

    function Get-ShellForgeSegmentStateText {
        param(
            [Parameter(Mandatory)]
            [string]$Label,

            [Parameter(Mandatory)]
            [bool]$Enabled
        )

        $markerRaw = if ($Enabled) { $checkGlyph } else { $crossGlyph }
        $markerColor = if ($Enabled) { $successColor } else { $errorColor }
        $labelColor = if ($Enabled) { $valueColor } else { $mutedColor }
        $raw = '{0} {1}' -f $markerRaw, $Label
        if (-not $useAnsi) {
            return [pscustomobject]@{
                Raw    = $raw
                Styled = $raw
            }
        }

        $styled = '{0} {1}' -f
            (Get-ShellForgeAnsiText -Text $markerRaw -HexColor $markerColor),
            (Get-ShellForgeAnsiText -Text $Label -HexColor $labelColor)

        return [pscustomobject]@{
            Raw    = $raw
            Styled = $styled
        }
    }

    function Join-ShellForgeCardParts {
        param(
            [Parameter(Mandatory)]
            [pscustomobject[]]$Items
        )

        $rawItems = [System.Collections.Generic.List[string]]::new()
        $styledItems = [System.Collections.Generic.List[string]]::new()
        foreach ($item in @($Items)) {
            if ($null -eq $item) {
                continue
            }

            [void]$rawItems.Add([string]$item.Raw)
            [void]$styledItems.Add([string]$item.Styled)
        }

        $rawText = $rawItems -join '  '
        $styledText = $styledItems -join '  '
        return [pscustomobject]@{
            Raw    = $rawText
            Styled = $styledText
        }
    }

    $topBorder = if ($useAnsi) { Get-ShellForgeAnsiText -Text $topBorderRaw -HexColor $borderColor } else { $topBorderRaw }
    $middleBorder = if ($useAnsi) { Get-ShellForgeAnsiText -Text $middleBorderRaw -HexColor $borderColor } else { $middleBorderRaw }
    $bottomBorder = if ($useAnsi) { Get-ShellForgeAnsiText -Text $bottomBorderRaw -HexColor $borderColor } else { $bottomBorderRaw }
    if ($useAnsi) {
        Write-Host $topBorder
    }
    else {
        Write-Host $topBorder -ForegroundColor DarkCyan
    }

    $headerLeftRaw = '  ' + $diamond + '  ' + $Theme.name
    $headerRightRaw = $category
    $headerSpacing = $innerWidth - $headerLeftRaw.Length - $headerRightRaw.Length
    if ($headerSpacing -lt 2) {
        $headerSpacing = 2
    }

    $headerRaw = $headerLeftRaw + (' ' * $headerSpacing) + $headerRightRaw
    $headerStyled = ''
    if ($useAnsi) {
        $headerStyled = ('{0}{1}{2}' -f
            (Get-ShellForgeAnsiText -Text ('  ' + $diamond + '  ') -HexColor $accentColor),
            (Get-ShellForgeAnsiText -Text $Theme.name -HexColor $titleColor),
            (Get-ShellForgeAnsiText -Text ((' ' * $headerSpacing) + $category) -HexColor $mutedColor))
    }
    Write-ShellForgeCardLine -RawText $headerRaw -StyledText $headerStyled -FallbackColor White

    $descriptorRaw = '    ' + $descriptor
    $descriptorStyled = if ($useAnsi) { Get-ShellForgeAnsiText -Text $descriptorRaw -HexColor $valueColor } else { '' }
    Write-ShellForgeCardLine -RawText $descriptorRaw -StyledText $descriptorStyled -FallbackColor Gray

    if ($useAnsi) {
        Write-Host $middleBorder
    }
    else {
        Write-Host $middleBorder -ForegroundColor DarkCyan
    }

    $palettePrefixRaw = '  Palette   '
    $paletteRaw = 'bg sf ac a2 tx mu ok wa er'
    $paletteStyled = ''
    if ($useAnsi) {
        $paletteStyled = (Get-ShellForgeAnsiText -Text $palettePrefixRaw -HexColor $keyColor) + (Get-ShellForgePalettePreviewText -Theme $Theme)
    }
    Write-ShellForgeCardLine -RawText ($palettePrefixRaw + $paletteRaw) -StyledText $paletteStyled -FallbackColor Gray

    if ($useAnsi) {
        Write-Host $middleBorder
    }
    else {
        Write-Host $middleBorder -ForegroundColor DarkCyan
    }

    $segmentPrimary = Join-ShellForgeCardParts -Items @(
        (Get-ShellForgeSegmentStateText -Label 'git' -Enabled ([bool]$Theme.segments.gitEnabled)),
        (Get-ShellForgeSegmentStateText -Label 'status' -Enabled ([bool]$Theme.segments.statusEnabled)),
        (Get-ShellForgeSegmentStateText -Label 'admin' -Enabled ([bool]$Theme.segments.adminEnabled)),
        (Get-ShellForgeSegmentStateText -Label 'runtime' -Enabled ([bool]$Theme.segments.runtimeEnabled)),
        (Get-ShellForgeSegmentStateText -Label 'exec' -Enabled ([bool]$Theme.segments.executionTimeEnabled))
    )

    $segmentContext = Join-ShellForgeCardParts -Items @(
        (Get-ShellForgeSegmentStateText -Label 'clock' -Enabled ([bool]$Theme.segments.timeEnabled)),
        (Get-ShellForgeSegmentStateText -Label 'host' -Enabled ([bool]$Theme.segments.hostEnabled)),
        (Get-ShellForgeSegmentStateText -Label 'user' -Enabled ([bool]$Theme.segments.userEnabled)),
        (Get-ShellForgeSegmentStateText -Label 'battery' -Enabled ([bool]$Theme.segments.batteryEnabled))
    )

    $segmentsPrefixRaw = '  Segments  '
    $segmentsStyled = ''
    if ($useAnsi) {
        $segmentsStyled = (Get-ShellForgeAnsiText -Text $segmentsPrefixRaw -HexColor $keyColor) + $segmentPrimary.Styled
    }
    Write-ShellForgeCardLine -RawText ($segmentsPrefixRaw + $segmentPrimary.Raw) -StyledText $segmentsStyled -FallbackColor Gray

    $segmentsContinuationRaw = '            ' + $segmentContext.Raw
    $segmentsContinuationStyled = ''
    if ($useAnsi) {
        $segmentsContinuationStyled = (' ' * 12) + $segmentContext.Styled
    }
    Write-ShellForgeCardLine -RawText $segmentsContinuationRaw -StyledText $segmentsContinuationStyled -FallbackColor Gray

    if ($useAnsi) {
        Write-Host $middleBorder
    }
    else {
        Write-Host $middleBorder -ForegroundColor DarkCyan
    }

    $layoutRaw = '  Layout    {0}{1}{2}{1}{3}{1}{4}' -f $Theme.promptLayout.type, $dividerText, $Theme.promptLayout.lineMode, $Theme.promptLayout.density, ('path:' + $Theme.segments.pathMode)
    $layoutStyled = ''
    if ($useAnsi) {
        $layoutStyled = (Get-ShellForgeAnsiText -Text '  Layout    ' -HexColor $keyColor) + (Get-ShellForgeAnsiText -Text ($layoutRaw.Substring(12)) -HexColor $valueColor)
    }
    Write-ShellForgeCardLine -RawText $layoutRaw -StyledText $layoutStyled -FallbackColor Gray

    $terminalValue = '{0}{1}{2}{1}{3}%' -f $Theme.terminal.fontRecommendation, $dividerText, $Theme.terminal.cursorStyle, $Theme.terminal.opacityPercent
    $terminalRaw = '  Terminal  ' + $terminalValue
    $terminalStyled = ''
    if ($useAnsi) {
        $terminalStyled = (Get-ShellForgeAnsiText -Text '  Terminal  ' -HexColor $keyColor) + (Get-ShellForgeAnsiText -Text $terminalValue -HexColor $valueColor)
    }
    Write-ShellForgeCardLine -RawText $terminalRaw -StyledText $terminalStyled -FallbackColor Gray

    if ($useAnsi) {
        Write-Host $middleBorder
    }
    else {
        Write-Host $middleBorder -ForegroundColor DarkCyan
    }

    $previewPrefixRaw = '  ' + $pointer + '  '
    $previewRaw = $previewPrefixRaw + [string]$Theme.preview.promptExample
    $previewStyled = ''
    if ($useAnsi) {
        $previewStyled = (Get-ShellForgeAnsiText -Text $previewPrefixRaw -HexColor $accentColor) + (Get-ShellForgeAnsiText -Text ([string]$Theme.preview.promptExample) -HexColor '#9DD4E8')
    }
    Write-ShellForgeCardLine -RawText $previewRaw -StyledText $previewStyled -FallbackColor White

    $sampleRaw = '  Sample    ' + [string]$Theme.preview.sampleCommand
    $sampleStyled = ''
    if ($useAnsi) {
        $sampleStyled = (Get-ShellForgeAnsiText -Text '  Sample    ' -HexColor $keyColor) + (Get-ShellForgeAnsiText -Text ([string]$Theme.preview.sampleCommand) -HexColor $warningColor)
    }
    Write-ShellForgeCardLine -RawText $sampleRaw -StyledText $sampleStyled -FallbackColor Gray

    if ($useAnsi) {
        Write-Host $bottomBorder
    }
    else {
        Write-Host $bottomBorder -ForegroundColor DarkCyan
    }
    Write-Host ''
}

function Write-ShellForgeMenuOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Index,

        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter()]
        [AllowEmptyString()]
        [string]$Detail = ''
    )

    if (Test-ShellForgeVirtualTerminalSupport) {
        if ($Index -eq 0) {
            $indexText = Get-ShellForgeAnsiText -Text ' [0]' -HexColor '#FF5D7A'
            $labelText = Get-ShellForgeAnsiText -Text ('  ' + $Text) -HexColor '#6A7A84'
        }
        else {
            $indexText = Get-ShellForgeAnsiText -Text (' [{0}]' -f $Index) -HexColor '#4DD0E1'
            $labelText = Get-ShellForgeAnsiText -Text ('  ' + $Text) -HexColor '#E8F7FF'
        }

        Write-Host ('{0}{1}' -f $indexText, $labelText)
        if (-not [string]::IsNullOrWhiteSpace($Detail)) {
            Write-Host (Get-ShellForgeAnsiText -Text ('      ' + $Detail) -HexColor '#3A5060')
        }

        return
    }

    if ($Index -eq 0) {
        Write-Host (' [0] {0}' -f $Text) -ForegroundColor DarkGray
    }
    else {
        Write-Host (' [{0}] {1}' -f $Index, $Text) -ForegroundColor White
    }

    if (-not [string]::IsNullOrWhiteSpace($Detail)) {
        Write-Host ('      {0}' -f $Detail) -ForegroundColor DarkGray
    }
}
