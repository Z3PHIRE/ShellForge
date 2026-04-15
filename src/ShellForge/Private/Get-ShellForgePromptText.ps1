Set-StrictMode -Version Latest

function Test-ShellForgeVirtualTerminalSupport {
    [CmdletBinding()]
    param()

    if ($null -ne (Get-Variable -Name PSStyle -Scope Global -ErrorAction SilentlyContinue)) {
        return $true
    }

    try {
        if ($Host.UI.PSObject.Properties.Name -contains 'SupportsVirtualTerminal') {
            return [bool]$Host.UI.SupportsVirtualTerminal
        }
    }
    catch {
    }

    if (-not [string]::IsNullOrWhiteSpace($env:WT_SESSION)) {
        return $true
    }

    if (-not [string]::IsNullOrWhiteSpace($env:TERM)) {
        return $true
    }

    return $false
}

function ConvertTo-ShellForgeAnsiSequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$HexColor
    )

    $trimmedColor = $HexColor.TrimStart('#')
    if ($trimmedColor.Length -ne 6) {
        return ''
    }

    try {
        $red = [Convert]::ToInt32($trimmedColor.Substring(0, 2), 16)
        $green = [Convert]::ToInt32($trimmedColor.Substring(2, 2), 16)
        $blue = [Convert]::ToInt32($trimmedColor.Substring(4, 2), 16)
        return ('{0}[38;2;{1};{2};{3}m' -f [char]27, $red, $green, $blue)
    }
    catch {
        return ''
    }
}

function Get-ShellForgeAnsiText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [string]$HexColor
    )

    if ($null -ne (Get-Variable -Name PSStyle -Scope Global -ErrorAction SilentlyContinue)) {
        return "$($PSStyle.Foreground.FromRgb($HexColor))$Text$($PSStyle.Reset)"
    }

    if (Test-ShellForgeVirtualTerminalSupport) {
        $ansiSequence = ConvertTo-ShellForgeAnsiSequence -HexColor $HexColor
        if (-not [string]::IsNullOrWhiteSpace($ansiSequence)) {
            return ('{0}{1}{2}[0m' -f $ansiSequence, $Text, [char]27)
        }
    }

    return $Text
}

function Get-ShellForgeCompactPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PathValue,

        [Parameter(Mandatory)]
        [ValidateSet('Leaf', 'Short', 'Full')]
        [string]$Mode
    )

    $pathWithHome = $PathValue
    if ($pathWithHome.StartsWith($HOME, [System.StringComparison]::OrdinalIgnoreCase)) {
        $pathWithHome = $pathWithHome.Replace($HOME, '~')
    }

    switch ($Mode) {
        'Leaf' {
            $leafName = Split-Path -Path $pathWithHome -Leaf
            if ([string]::IsNullOrWhiteSpace($leafName)) {
                return $pathWithHome
            }

            return $leafName
        }
        'Short' {
            $separatorPattern = '[\\/]'
            $parts = $pathWithHome -split $separatorPattern
            if ($parts.Count -le 3) {
                return $pathWithHome
            }

            $separator = if ($pathWithHome.Contains('\')) { '\' } else { '/' }
            $meaningfulParts = @($parts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            if ($meaningfulParts.Count -le 3) {
                return $pathWithHome
            }

            $displayParts = [System.Collections.Generic.List[string]]::new()
            [void]$displayParts.Add($meaningfulParts[0])
            [void]$displayParts.Add('..')
            [void]$displayParts.Add($meaningfulParts[$meaningfulParts.Count - 2])
            [void]$displayParts.Add($meaningfulParts[$meaningfulParts.Count - 1])
            return ($displayParts -join $separator)
        }
        default {
            return $pathWithHome
        }
    }
}

function Get-ShellForgeGitState {
    [CmdletBinding()]
    param()

    if (-not (Get-Command -Name git -ErrorAction SilentlyContinue)) {
        return $null
    }

    try {
        $null = & git rev-parse --is-inside-work-tree 2>$null
        if ($LASTEXITCODE -ne 0) {
            return $null
        }

        $branchName = (& git rev-parse --abbrev-ref HEAD 2>$null | Select-Object -First 1).Trim()
        $porcelainStatus = @(& git status --porcelain 2>$null)
        $isDirty = $porcelainStatus.Count -gt 0
        return [pscustomobject]@{
            Branch = $branchName
            Dirty  = $isDirty
        }
    }
    catch {
        return $null
    }
}

function Get-ShellForgeExecutionTime {
    [CmdletBinding()]
    param()

    try {
        $lastHistoryItem = Get-History -Count 1 -ErrorAction Stop | Select-Object -First 1
        if ($null -eq $lastHistoryItem) {
            return $null
        }

        if ($null -eq $lastHistoryItem.EndExecutionTime -or $null -eq $lastHistoryItem.StartExecutionTime) {
            return $null
        }

        $duration = $lastHistoryItem.EndExecutionTime - $lastHistoryItem.StartExecutionTime
        if ($duration.TotalMilliseconds -lt 1) {
            return $null
        }

        if ($duration.TotalSeconds -ge 60) {
            return ('{0:n1}m' -f $duration.TotalMinutes)
        }

        if ($duration.TotalSeconds -ge 1) {
            return ('{0:n1}s' -f $duration.TotalSeconds)
        }

        return ('{0:n0}ms' -f $duration.TotalMilliseconds)
    }
    catch {
        return $null
    }
}

function Get-ShellForgeRuntimeText {
    [CmdletBinding()]
    param()

    return ('PS {0}.{1}' -f $PSVersionTable.PSVersion.Major, $PSVersionTable.PSVersion.Minor)
}

function Get-ShellForgeBatteryState {
    [CmdletBinding()]
    param()

    $platformInfo = Get-ShellForgePlatformInfo
    if ($platformInfo.Platform -ne 'Windows') {
        return $null
    }

    try {
        $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop | Select-Object -First 1
        if ($null -eq $battery) {
            return $null
        }

        return '{0}%%' -f [int]$battery.EstimatedChargeRemaining
    }
    catch {
        return $null
    }
}

function Test-ShellForgeAdministrator {
    [CmdletBinding()]
    param()

    $platformInfo = Get-ShellForgePlatformInfo
    if ($platformInfo.Platform -eq 'Windows') {
        try {
            $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = [Security.Principal.WindowsPrincipal]::new($identity)
            return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }
        catch {
            return $false
        }
    }

    try {
        return ([Environment]::UserName -eq 'root')
    }
    catch {
        return $false
    }
}

function Get-ShellForgeLayoutTokens {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme
    )

    switch ($Theme.promptLayout.type) {
        'Glass' {
            return [pscustomobject]@{ Left = '['; Right = ']'; Joiner = ' '; Divider = ' / ' }
        }
        'Minimal' {
            return [pscustomobject]@{ Left = ''; Right = ''; Joiner = '  '; Divider = ' ' }
        }
        'Tactical' {
            return [pscustomobject]@{ Left = '<'; Right = '>'; Joiner = ' '; Divider = ' | ' }
        }
        'Grid' {
            return [pscustomobject]@{ Left = '{'; Right = '}'; Joiner = ' '; Divider = ' :: ' }
        }
        'Nordic' {
            return [pscustomobject]@{ Left = '('; Right = ')'; Joiner = ' '; Divider = ' -> ' }
        }
        'SOC' {
            return [pscustomobject]@{ Left = '['; Right = ']'; Joiner = ' '; Divider = ' || ' }
        }
        'Boxed' {
            return [pscustomobject]@{ Left = '| '; Right = ' |'; Joiner = ' '; Divider = ' | ' }
        }
        'PathHeavy' {
            return [pscustomobject]@{ Left = ''; Right = ''; Joiner = ' '; Divider = ' // ' }
        }
        'Matrix' {
            return [pscustomobject]@{ Left = ''; Right = ''; Joiner = ' '; Divider = ' :: ' }
        }
        default {
            return [pscustomobject]@{ Left = '['; Right = ']'; Joiner = ' '; Divider = ' / ' }
        }
    }
}

function Get-ShellForgeSegmentLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('status', 'admin', 'user', 'host', 'path', 'git', 'runtime', 'time', 'exec', 'battery')]
        [string]$SegmentName,

        [Parameter(Mandatory)]
        [ValidateSet('None', 'Low', 'Medium', 'High')]
        [string]$IconDensity
    )

    switch ($IconDensity) {
        'None' {
            return ''
        }
        'Low' {
            switch ($SegmentName) {
                'status' { return '' }
                'admin' { return '!' }
                'user' { return 'u' }
                'host' { return '@' }
                'path' { return '' }
                'git' { return 'git' }
                'runtime' { return 'ps' }
                'time' { return 't' }
                'exec' { return 'dt' }
                'battery' { return 'bat' }
            }
        }
        'Medium' {
            switch ($SegmentName) {
                'status' { return '' }
                'admin' { return 'admin' }
                'user' { return 'usr' }
                'host' { return 'host' }
                'path' { return '' }
                'git' { return 'git' }
                'runtime' { return 'ps' }
                'time' { return 'time' }
                'exec' { return 'exec' }
                'battery' { return 'battery' }
            }
        }
        'High' {
            switch ($SegmentName) {
                'status' { return 'status' }
                'admin' { return 'elevation' }
                'user' { return 'user' }
                'host' { return 'host' }
                'path' { return 'path' }
                'git' { return 'git' }
                'runtime' { return 'powershell' }
                'time' { return 'clock' }
                'exec' { return 'duration' }
                'battery' { return 'battery' }
            }
        }
    }
}

function Format-ShellForgeSegment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text,

        [Parameter(Mandatory)]
        [ValidateSet('status', 'admin', 'user', 'host', 'path', 'git', 'runtime', 'time', 'exec', 'battery')]
        [string]$SegmentName,

        [Parameter(Mandatory)]
        [pscustomobject]$Theme,

        [Parameter(Mandatory)]
        [pscustomobject]$Tokens
    )

    $label = Get-ShellForgeSegmentLabel -SegmentName $SegmentName -IconDensity $Theme.iconDensity
    $displayText = if ([string]::IsNullOrWhiteSpace($label)) { $Text } else { '{0} {1}' -f $label, $Text }

    switch ($SegmentName) {
        'status' { $segmentColor = if ($Text -like 'ok*') { $Theme.palette.success } else { $Theme.palette.error } }
        'admin' { $segmentColor = $Theme.palette.warning }
        'user' { $segmentColor = $Theme.palette.info }
        'host' { $segmentColor = $Theme.palette.accentSecondary }
        'path' { $segmentColor = $Theme.palette.accent }
        'git' { $segmentColor = $Theme.palette.accentSecondary }
        'runtime' { $segmentColor = $Theme.palette.info }
        'time' { $segmentColor = $Theme.palette.muted }
        'exec' { $segmentColor = $Theme.palette.warning }
        'battery' { $segmentColor = $Theme.palette.warning }
        default { $segmentColor = $Theme.palette.text }
    }

    $wrappedText = '{0}{1}{2}' -f $Tokens.Left, $displayText, $Tokens.Right
    return Get-ShellForgeAnsiText -Text $wrappedText -HexColor $segmentColor
}

function Get-ShellForgePromptGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('status', 'admin', 'user', 'host', 'path', 'git', 'runtime', 'time', 'exec', 'battery')]
        [string]$SegmentName
    )

    switch ($SegmentName) {
        'status' { return 'Primary' }
        'admin' { return 'Primary' }
        'path' { return 'Primary' }
        'git' { return 'Primary' }
        default { return 'Context' }
    }
}

function Join-ShellForgePromptSegments {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowEmptyCollection()]
        [string[]]$Segments,

        [Parameter(Mandatory)]
        [string]$Joiner
    )

    $filteredSegments = @($Segments | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($filteredSegments.Count -eq 0) {
        return ''
    }

    return ($filteredSegments -join $Joiner)
}

function Get-ShellForgePromptText {
    [CmdletBinding()]
    param()

    if ($null -eq $script:ShellForgeCurrentTheme) {
        return 'PS> '
    }

    $theme = $script:ShellForgeCurrentTheme
    $tokens = Get-ShellForgeLayoutTokens -Theme $theme
    $segmentValues = [System.Collections.Generic.List[object]]::new()

    $lastSuccess = $?
    $lastExitCode = $null
    $lastExitCodeVariable = Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
    if ($null -ne $lastExitCodeVariable) {
        $lastExitCode = $lastExitCodeVariable.Value
    }
    if ($theme.segments.statusEnabled) {
        $statusText = if ($lastSuccess -and ($lastExitCode -eq 0 -or $null -eq $lastExitCode)) { 'OK' } else { 'ERR {0}' -f $lastExitCode }
        [void]$segmentValues.Add([pscustomobject]@{
            Name     = 'status'
            Group    = Get-ShellForgePromptGroup -SegmentName 'status'
            Rendered = (Format-ShellForgeSegment -Text $statusText -SegmentName 'status' -Theme $theme -Tokens $tokens)
        })
    }

    if ($theme.segments.adminEnabled -and (Test-ShellForgeAdministrator)) {
        $adminText = switch ($theme.promptLayout.adminWarningStyle) {
            'Banner' { 'ADMIN MODE' }
            'Inline' { 'ADMIN' }
            default { 'ELEVATED' }
        }

        [void]$segmentValues.Add([pscustomobject]@{
            Name     = 'admin'
            Group    = Get-ShellForgePromptGroup -SegmentName 'admin'
            Rendered = (Format-ShellForgeSegment -Text $adminText -SegmentName 'admin' -Theme $theme -Tokens $tokens)
        })
    }

    if ($theme.segments.userEnabled) {
        [void]$segmentValues.Add([pscustomobject]@{
            Name     = 'user'
            Group    = Get-ShellForgePromptGroup -SegmentName 'user'
            Rendered = (Format-ShellForgeSegment -Text ([Environment]::UserName) -SegmentName 'user' -Theme $theme -Tokens $tokens)
        })
    }

    if ($theme.segments.hostEnabled) {
        [void]$segmentValues.Add([pscustomobject]@{
            Name     = 'host'
            Group    = Get-ShellForgePromptGroup -SegmentName 'host'
            Rendered = (Format-ShellForgeSegment -Text ([Environment]::MachineName) -SegmentName 'host' -Theme $theme -Tokens $tokens)
        })
    }

    $currentPath = Get-ShellForgeCompactPath -PathValue (Get-Location).Path -Mode $theme.segments.pathMode
    [void]$segmentValues.Add([pscustomobject]@{
        Name     = 'path'
        Group    = Get-ShellForgePromptGroup -SegmentName 'path'
        Rendered = (Format-ShellForgeSegment -Text $currentPath -SegmentName 'path' -Theme $theme -Tokens $tokens)
    })

    if ($theme.segments.gitEnabled) {
        $gitState = Get-ShellForgeGitState
        if ($null -ne $gitState) {
            $gitText = if ($gitState.Dirty) { '{0}*' -f $gitState.Branch } else { $gitState.Branch }
            [void]$segmentValues.Add([pscustomobject]@{
                Name     = 'git'
                Group    = Get-ShellForgePromptGroup -SegmentName 'git'
                Rendered = (Format-ShellForgeSegment -Text $gitText -SegmentName 'git' -Theme $theme -Tokens $tokens)
            })
        }
    }

    if ($theme.segments.runtimeEnabled) {
        [void]$segmentValues.Add([pscustomobject]@{
            Name     = 'runtime'
            Group    = Get-ShellForgePromptGroup -SegmentName 'runtime'
            Rendered = (Format-ShellForgeSegment -Text (Get-ShellForgeRuntimeText) -SegmentName 'runtime' -Theme $theme -Tokens $tokens)
        })
    }

    if ($theme.segments.executionTimeEnabled) {
        $executionTime = Get-ShellForgeExecutionTime
        if ($null -ne $executionTime) {
            [void]$segmentValues.Add([pscustomobject]@{
                Name     = 'exec'
                Group    = Get-ShellForgePromptGroup -SegmentName 'exec'
                Rendered = (Format-ShellForgeSegment -Text $executionTime -SegmentName 'exec' -Theme $theme -Tokens $tokens)
            })
        }
    }

    if ($theme.segments.timeEnabled) {
        [void]$segmentValues.Add([pscustomobject]@{
            Name     = 'time'
            Group    = Get-ShellForgePromptGroup -SegmentName 'time'
            Rendered = (Format-ShellForgeSegment -Text ([DateTime]::Now.ToString('HH:mm')) -SegmentName 'time' -Theme $theme -Tokens $tokens)
        })
    }

    if ($theme.segments.batteryEnabled) {
        $batteryState = Get-ShellForgeBatteryState
        if ($null -ne $batteryState) {
            [void]$segmentValues.Add([pscustomobject]@{
                Name     = 'battery'
                Group    = Get-ShellForgePromptGroup -SegmentName 'battery'
                Rendered = (Format-ShellForgeSegment -Text $batteryState -SegmentName 'battery' -Theme $theme -Tokens $tokens)
            })
        }
    }

    $withinGroupJoiner = if ($theme.promptLayout.density -eq 'High') { $tokens.Divider } elseif ($theme.promptLayout.density -eq 'Low') { ' ' } else { $tokens.Joiner }
    $betweenGroupJoiner = if ($theme.promptLayout.type -eq 'Minimal') { '   ' } else { '   {0}   ' -f $tokens.Divider.Trim() }
    $primaryLine = Join-ShellForgePromptSegments -Segments @($segmentValues | Where-Object { $_.Group -eq 'Primary' } | Select-Object -ExpandProperty Rendered) -Joiner $withinGroupJoiner
    $contextLine = Join-ShellForgePromptSegments -Segments @($segmentValues | Where-Object { $_.Group -eq 'Context' } | Select-Object -ExpandProperty Rendered) -Joiner $withinGroupJoiner
    $promptSymbol = Get-ShellForgeAnsiText -Text $theme.promptLayout.promptSymbol -HexColor $theme.palette.text

    if ($theme.promptLayout.lineMode -eq 'DoubleLine') {
        if ([string]::IsNullOrWhiteSpace($contextLine)) {
            return '{0} {1} ' -f $promptSymbol, $primaryLine
        }

        return '{0}{1}{2} {3} ' -f $contextLine, [Environment]::NewLine, $promptSymbol, $primaryLine
    }

    if ([string]::IsNullOrWhiteSpace($contextLine)) {
        return '{0} {1} ' -f $promptSymbol, $primaryLine
    }

    return '{0} {1}{2}{3} ' -f $promptSymbol, $primaryLine, $betweenGroupJoiner, $contextLine
}
