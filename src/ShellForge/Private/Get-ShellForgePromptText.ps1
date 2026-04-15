Set-StrictMode -Version Latest

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
            if ($parts.Count -le 2) {
                return $pathWithHome
            }

            $shortParts = [System.Collections.Generic.List[string]]::new()
            for ($index = 0; $index -lt $parts.Count; $index++) {
                $currentPart = $parts[$index]
                if ([string]::IsNullOrWhiteSpace($currentPart)) {
                    if ($index -eq 0) {
                        [void]$shortParts.Add('')
                    }

                    continue
                }

                if ($index -lt ($parts.Count - 1)) {
                    if ($currentPart -eq '~') {
                        [void]$shortParts.Add('~')
                    }
                    else {
                        [void]$shortParts.Add($currentPart.Substring(0, 1))
                    }
                }
                else {
                    [void]$shortParts.Add($currentPart)
                }
            }

            $separator = if ($pathWithHome.Contains('\')) { '\' } else { '/' }
            return ($shortParts -join $separator)
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
                'status' { return 'st' }
                'admin' { return 'adm' }
                'user' { return 'u' }
                'host' { return 'h' }
                'path' { return '~' }
                'git' { return 'git' }
                'runtime' { return 'ps' }
                'time' { return 't' }
                'exec' { return 'dt' }
                'battery' { return 'bat' }
            }
        }
        'Medium' {
            switch ($SegmentName) {
                'status' { return 'status' }
                'admin' { return 'admin' }
                'user' { return 'user' }
                'host' { return 'host' }
                'path' { return 'path' }
                'git' { return 'git' }
                'runtime' { return 'runtime' }
                'time' { return 'time' }
                'exec' { return 'exec' }
                'battery' { return 'battery' }
            }
        }
        'High' {
            switch ($SegmentName) {
                'status' { return 'status:' }
                'admin' { return 'admin:' }
                'user' { return 'user:' }
                'host' { return 'host:' }
                'path' { return 'path:' }
                'git' { return 'git:' }
                'runtime' { return 'runtime:' }
                'time' { return 'time:' }
                'exec' { return 'duration:' }
                'battery' { return 'battery:' }
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

function Get-ShellForgePromptText {
    [CmdletBinding()]
    param()

    if ($null -eq $script:ShellForgeCurrentTheme) {
        return 'PS> '
    }

    $theme = $script:ShellForgeCurrentTheme
    $tokens = Get-ShellForgeLayoutTokens -Theme $theme
    $segmentValues = [System.Collections.Generic.List[string]]::new()

    $lastSuccess = $?
    $lastExitCode = $global:LASTEXITCODE
    if ($theme.segments.statusEnabled) {
        $statusText = if ($lastSuccess -and ($lastExitCode -eq 0 -or $null -eq $lastExitCode)) { 'ok' } else { 'err {0}' -f $lastExitCode }
        [void]$segmentValues.Add((Format-ShellForgeSegment -Text $statusText -SegmentName 'status' -Theme $theme -Tokens $tokens))
    }

    if ($theme.segments.adminEnabled -and (Test-ShellForgeAdministrator)) {
        $adminText = switch ($theme.promptLayout.adminWarningStyle) {
            'Banner' { 'ADMIN MODE' }
            'Inline' { 'admin' }
            default { 'elevated' }
        }

        [void]$segmentValues.Add((Format-ShellForgeSegment -Text $adminText -SegmentName 'admin' -Theme $theme -Tokens $tokens))
    }

    if ($theme.segments.userEnabled) {
        [void]$segmentValues.Add((Format-ShellForgeSegment -Text ([Environment]::UserName) -SegmentName 'user' -Theme $theme -Tokens $tokens))
    }

    if ($theme.segments.hostEnabled) {
        [void]$segmentValues.Add((Format-ShellForgeSegment -Text ([Environment]::MachineName) -SegmentName 'host' -Theme $theme -Tokens $tokens))
    }

    $currentPath = Get-ShellForgeCompactPath -PathValue (Get-Location).Path -Mode $theme.segments.pathMode
    [void]$segmentValues.Add((Format-ShellForgeSegment -Text $currentPath -SegmentName 'path' -Theme $theme -Tokens $tokens))

    if ($theme.segments.gitEnabled) {
        $gitState = Get-ShellForgeGitState
        if ($null -ne $gitState) {
            $gitText = if ($gitState.Dirty) { '{0}*' -f $gitState.Branch } else { $gitState.Branch }
            [void]$segmentValues.Add((Format-ShellForgeSegment -Text $gitText -SegmentName 'git' -Theme $theme -Tokens $tokens))
        }
    }

    if ($theme.segments.runtimeEnabled) {
        [void]$segmentValues.Add((Format-ShellForgeSegment -Text ('PS {0}' -f $PSVersionTable.PSVersion) -SegmentName 'runtime' -Theme $theme -Tokens $tokens))
    }

    if ($theme.segments.executionTimeEnabled) {
        $executionTime = Get-ShellForgeExecutionTime
        if ($null -ne $executionTime) {
            [void]$segmentValues.Add((Format-ShellForgeSegment -Text $executionTime -SegmentName 'exec' -Theme $theme -Tokens $tokens))
        }
    }

    if ($theme.segments.timeEnabled) {
        [void]$segmentValues.Add((Format-ShellForgeSegment -Text ([DateTime]::Now.ToString('HH:mm:ss')) -SegmentName 'time' -Theme $theme -Tokens $tokens))
    }

    if ($theme.segments.batteryEnabled) {
        $batteryState = Get-ShellForgeBatteryState
        if ($null -ne $batteryState) {
            [void]$segmentValues.Add((Format-ShellForgeSegment -Text $batteryState -SegmentName 'battery' -Theme $theme -Tokens $tokens))
        }
    }

    $joiner = if ($theme.promptLayout.density -eq 'High') { $tokens.Divider } elseif ($theme.promptLayout.density -eq 'Low') { ' ' } else { $tokens.Joiner }
    $firstLine = $segmentValues -join $joiner
    $promptSymbol = Get-ShellForgeAnsiText -Text $theme.promptLayout.promptSymbol -HexColor $theme.palette.text

    if ($theme.promptLayout.lineMode -eq 'DoubleLine') {
        return '{0}{1}{2} ' -f $firstLine, [Environment]::NewLine, $promptSymbol
    }

    return '{0}{1} ' -f $firstLine, $joiner + $promptSymbol
}

