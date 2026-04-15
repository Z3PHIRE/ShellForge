Set-StrictMode -Version Latest

function Write-ShellForgeDivider {
    [CmdletBinding()]
    param()

    Write-Host '------------------------------------------------------------' -ForegroundColor DarkGray
}

function Write-ShellForgeSectionTitle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Title
    )

    Write-Host ''
    Write-Host (' [{0}]' -f $Title.ToUpperInvariant()) -ForegroundColor Cyan
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

    $segments = [System.Collections.Generic.List[string]]::new()
    [void]$segments.Add(('path:{0}' -f $Theme.segments.pathMode.ToLowerInvariant()))
    if ($Theme.segments.gitEnabled) { [void]$segments.Add('git') }
    if ($Theme.segments.statusEnabled) { [void]$segments.Add('status') }
    if ($Theme.segments.adminEnabled) { [void]$segments.Add('admin') }
    return ($segments -join ', ')
}

function Get-ShellForgeThemeContextSegments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme
    )

    $segments = [System.Collections.Generic.List[string]]::new()
    if ($Theme.segments.runtimeEnabled) { [void]$segments.Add('runtime') }
    if ($Theme.segments.executionTimeEnabled) { [void]$segments.Add('exec time') }
    if ($Theme.segments.timeEnabled) { [void]$segments.Add('clock') }
    if ($Theme.segments.hostEnabled) { [void]$segments.Add('host') }
    if ($Theme.segments.userEnabled) { [void]$segments.Add('user') }
    if ($Theme.segments.batteryEnabled) { [void]$segments.Add('battery') }

    if ($segments.Count -eq 0) {
        return 'none'
    }

    return ($segments -join ', ')
}

function Get-ShellForgePalettePreviewText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme
    )

    $entries = @(
        @{ Label = 'bg'; Value = [string]$Theme.palette.background },
        @{ Label = 'surface'; Value = [string]$Theme.palette.surface },
        @{ Label = 'accent'; Value = [string]$Theme.palette.accent },
        @{ Label = 'accent2'; Value = [string]$Theme.palette.accentSecondary },
        @{ Label = 'text'; Value = [string]$Theme.palette.text }
    )

    $previewParts = [System.Collections.Generic.List[string]]::new()
    foreach ($entry in $entries) {
        $previewText = '{0} {1}' -f $entry.Label, $entry.Value
        [void]$previewParts.Add((Get-ShellForgeAnsiText -Text ('[{0}]' -f $previewText) -HexColor $entry.Value))
    }

    return ($previewParts -join '  ')
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

    Write-ShellForgeDivider
    Write-Host (' {0}' -f $Title) -ForegroundColor Cyan
    Write-Host ' premium terminal theme studio / deployment engine' -ForegroundColor DarkGray
    Write-Host (' {0}' -f $Subtitle) -ForegroundColor Gray
    Write-ShellForgeDivider
}

function Show-ShellForgeThemePreview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme
    )

    Write-ShellForgeSectionTitle -Title 'Identity'
    Write-Host ('  Name        : {0}' -f $Theme.name) -ForegroundColor White
    Write-Host ('  Category    : {0}' -f (Get-ShellForgeThemeCategory -Theme $Theme)) -ForegroundColor DarkCyan
    Write-Host ('  Layout      : {0} / {1} / {2}' -f $Theme.promptLayout.type, $Theme.promptLayout.lineMode, $Theme.promptLayout.density) -ForegroundColor White
    Write-Host ('  Intent      : {0}' -f $Theme.intent) -ForegroundColor Gray
    Write-Host ('  Personality : {0}' -f (Get-ShellForgeThemeDescriptor -Theme $Theme)) -ForegroundColor Gray

    Write-ShellForgeSectionTitle -Title 'Palette'
    Write-Host ('  {0}' -f (Get-ShellForgePalettePreviewText -Theme $Theme))

    Write-ShellForgeSectionTitle -Title 'Signal Design'
    Write-Host ('  Core signal : {0}' -f (Get-ShellForgeThemeCoreSegments -Theme $Theme)) -ForegroundColor White
    Write-Host ('  Context     : {0}' -f (Get-ShellForgeThemeContextSegments -Theme $Theme)) -ForegroundColor DarkGray

    Write-ShellForgeSectionTitle -Title 'Terminal'
    Write-Host ('  Font        : {0}' -f $Theme.terminal.fontRecommendation) -ForegroundColor White
    Write-Host ('  Background  : {0}' -f $Theme.terminal.backgroundHex) -ForegroundColor White
    Write-Host ('  Opacity     : {0}%' -f $Theme.terminal.opacityPercent) -ForegroundColor White
    Write-Host ('  Cursor      : {0}' -f $Theme.terminal.cursorStyle) -ForegroundColor White

    Write-ShellForgeSectionTitle -Title 'Compatibility'
    Write-Host ('  Native prompt : {0}' -f $Theme.compatibility.nativePromptSupported) -ForegroundColor White
    Write-Host ('  Oh My Posh    : {0}' -f $Theme.compatibility.ohMyPoshProfileAvailable) -ForegroundColor White
    Write-Host ('  Minimum PS    : {0}' -f $Theme.compatibility.minimumPowerShell) -ForegroundColor White

    Write-ShellForgeSectionTitle -Title 'Preview'
    Write-Host ('  Prompt  : {0}' -f $Theme.preview.promptExample) -ForegroundColor White
    Write-Host ('  Command : {0}' -f $Theme.preview.sampleCommand) -ForegroundColor Gray
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

    Write-Host (' [{0}] {1}' -f $Index, $Text) -ForegroundColor White
    if (-not [string]::IsNullOrWhiteSpace($Detail)) {
        Write-Host ('     {0}' -f $Detail) -ForegroundColor DarkGray
    }
}
