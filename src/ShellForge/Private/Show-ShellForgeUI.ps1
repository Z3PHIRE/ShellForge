Set-StrictMode -Version Latest

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

    Clear-Host
    Write-Host '============================================================' -ForegroundColor DarkGray
    Write-Host (' {0}' -f $Title) -ForegroundColor Cyan
    Write-Host (' {0}' -f $Subtitle) -ForegroundColor Gray
    Write-Host '============================================================' -ForegroundColor DarkGray
}

function Show-ShellForgeThemePreview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme
    )

    Write-Host ''
    Write-Host ('Theme: {0}' -f $Theme.name) -ForegroundColor Cyan
    Write-Host ('Intent: {0}' -f $Theme.intent) -ForegroundColor Gray
    Write-Host ('Description: {0}' -f $Theme.description) -ForegroundColor Gray
    Write-Host ('Layout: {0} / {1} / {2}' -f $Theme.promptLayout.type, $Theme.promptLayout.lineMode, $Theme.promptLayout.density) -ForegroundColor White
    Write-Host ('Palette: bg {0} | surface {1} | accent {2} | secondary {3}' -f $Theme.palette.background, $Theme.palette.surface, $Theme.palette.accent, $Theme.palette.accentSecondary) -ForegroundColor White
    Write-Host ('Segments: path {0} | git {1} | admin {2} | status {3} | runtime {4} | duration {5} | time {6} | host {7} | user {8} | battery {9}' -f
        $Theme.segments.pathMode,
        $Theme.segments.gitEnabled,
        $Theme.segments.adminEnabled,
        $Theme.segments.statusEnabled,
        $Theme.segments.runtimeEnabled,
        $Theme.segments.executionTimeEnabled,
        $Theme.segments.timeEnabled,
        $Theme.segments.hostEnabled,
        $Theme.segments.userEnabled,
        $Theme.segments.batteryEnabled) -ForegroundColor White
    Write-Host ('Recommended font: {0}' -f $Theme.terminal.fontRecommendation) -ForegroundColor DarkCyan
    Write-Host ('Compatibility: native {0} | oh-my-posh profile {1} | minimum PS {2}' -f
        $Theme.compatibility.nativePromptSupported,
        $Theme.compatibility.ohMyPoshProfileAvailable,
        $Theme.compatibility.minimumPowerShell) -ForegroundColor DarkGray
    Write-Host ''
    Write-Host 'Preview prompt sample:' -ForegroundColor Cyan
    Write-Host ('  {0}' -f $Theme.preview.promptExample) -ForegroundColor White
    Write-Host ('  Sample command: {0}' -f $Theme.preview.sampleCommand) -ForegroundColor Gray
    Write-Host ''
}

function Write-ShellForgeMenuOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Index,

        [Parameter(Mandatory)]
        [string]$Text
    )

    Write-Host (' [{0}] {1}' -f $Index, $Text) -ForegroundColor White
}

