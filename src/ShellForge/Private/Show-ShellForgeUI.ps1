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
        [ValidateSet('LightHorizontal', 'HeavyHorizontal', 'DoubleHorizontal', 'DashedHorizontal', 'TopLeft', 'TopRight', 'BottomLeft', 'BottomRight', 'Vertical', 'SectionBar', 'Diamond', 'Pointer', 'MiddleDot', 'Block', 'Check', 'Cross')]
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
        [string]$Style = 'Light'
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
        Write-Host (Get-ShellForgeAnsiText -Text $dividerText -HexColor '#1E3040')
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
    $keyColor = '#3A5A6A'
    $valueColor = '#B0CCD8'
    $nameColor = '#E8F7FF'
    $accentColor = '#4DD0E1'

    function Write-PreviewRow {
        param(
            [Parameter(Mandatory)]
            [string]$Key,

            [Parameter(Mandatory)]
            [string]$Value,

            [Parameter()]
            [string]$KeyHex = $keyColor,

            [Parameter()]
            [string]$ValueHex = $valueColor
        )

        if ($useAnsi) {
            $keyText = Get-ShellForgeAnsiText -Text ('  ' + $Key.PadRight(18)) -HexColor $KeyHex
            $valueText = Get-ShellForgeAnsiText -Text $Value -HexColor $ValueHex
            Write-Host ('{0}{1}' -f $keyText, $valueText)
        }
        else {
            Write-Host ('  {0,-18}{1}' -f $Key, $Value)
        }
    }

    function Write-CompatibilityRow {
        param(
            [Parameter(Mandatory)]
            [bool]$State,

            [Parameter(Mandatory)]
            [string]$Label
        )

        if ($useAnsi) {
            $symbolText = if ($State) { ' ' + (Get-ShellForgeUiGlyph -Name 'Check') + ' ' } else { ' ' + (Get-ShellForgeUiGlyph -Name 'Cross') + ' ' }
            $symbolColor = if ($State) { '#2EE6A6' } else { '#FF5D7A' }
            $labelColor = if ($State) { '#7BDCB5' } else { '#7B9BB7' }
            $symbol = Get-ShellForgeAnsiText -Text $symbolText -HexColor $symbolColor
            $labelText = Get-ShellForgeAnsiText -Text $Label -HexColor $labelColor
            Write-Host ('  {0}{1}' -f $symbol, $labelText)
        }
        else {
            $marker = if ($State) { '[ok]' } else { '[--]' }
            Write-Host ('  {0} {1}' -f $marker, $Label)
        }
    }

    Write-ShellForgeSectionTitle -Title 'Identity'
    Write-PreviewRow -Key 'Name' -Value $Theme.name -KeyHex $accentColor -ValueHex $nameColor
    Write-PreviewRow -Key 'Category' -Value (Get-ShellForgeThemeCategory -Theme $Theme)
    $layoutSeparator = '  ' + (Get-ShellForgeUiGlyph -Name 'MiddleDot') + '  '
    Write-PreviewRow -Key 'Layout' -Value ('{0}{1}{2}{1}{3}' -f $Theme.promptLayout.type, $layoutSeparator, $Theme.promptLayout.lineMode, $Theme.promptLayout.density)
    Write-PreviewRow -Key 'Intent' -Value [string]$Theme.intent
    Write-PreviewRow -Key 'Description' -Value (Get-ShellForgeThemeDescriptor -Theme $Theme)

    Write-ShellForgeSectionTitle -Title 'Palette'
    Write-Host ('  {0}' -f (Get-ShellForgePalettePreviewText -Theme $Theme))

    Write-ShellForgeSectionTitle -Title 'Signal Design'
    Write-PreviewRow -Key 'Primary' -Value (Get-ShellForgeThemeCoreSegments -Theme $Theme)
    Write-PreviewRow -Key 'Context' -Value (Get-ShellForgeThemeContextSegments -Theme $Theme)

    Write-ShellForgeSectionTitle -Title 'Terminal'
    Write-PreviewRow -Key 'Font' -Value [string]$Theme.terminal.fontRecommendation
    Write-PreviewRow -Key 'Background' -Value [string]$Theme.terminal.backgroundHex
    Write-PreviewRow -Key 'Opacity' -Value ('{0}%' -f $Theme.terminal.opacityPercent)
    Write-PreviewRow -Key 'Cursor' -Value [string]$Theme.terminal.cursorStyle

    Write-ShellForgeSectionTitle -Title 'Compatibility'
    Write-CompatibilityRow -State $Theme.compatibility.nativePromptSupported -Label 'Native prompt (no external dependency)'
    Write-CompatibilityRow -State $Theme.compatibility.ohMyPoshProfileAvailable -Label 'Oh My Posh profile available'
    Write-PreviewRow -Key 'Minimum PS' -Value [string]$Theme.compatibility.minimumPowerShell

    Write-ShellForgeSectionTitle -Title 'Preview'
    Write-PreviewRow -Key 'Prompt' -Value [string]$Theme.preview.promptExample -ValueHex '#9DD4E8'
    Write-PreviewRow -Key 'Sample' -Value [string]$Theme.preview.sampleCommand
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
