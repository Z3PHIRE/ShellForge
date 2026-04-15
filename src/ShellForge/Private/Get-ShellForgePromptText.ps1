Set-StrictMode -Version Latest

function Test-ShellForgeVirtualTerminalSupport {
    [CmdletBinding()]
    param()

    try {
        if ([Console]::IsOutputRedirected -or [Console]::IsErrorRedirected) {
            return $false
        }
    }
    catch {
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

    if ($null -ne (Get-Variable -Name PSStyle -Scope Global -ErrorAction SilentlyContinue)) {
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

    if (-not (Test-ShellForgeHexColor -Value $HexColor)) {
        return $Text
    }

    if (-not (Test-ShellForgeVirtualTerminalSupport)) {
        return $Text
    }

    if ($null -ne (Get-Variable -Name PSStyle -Scope Global -ErrorAction SilentlyContinue)) {
        return "$($PSStyle.Foreground.FromRgb($HexColor))$Text$($PSStyle.Reset)"
    }

    $ansiSequence = ConvertTo-ShellForgeAnsiSequence -HexColor $HexColor
    if (-not [string]::IsNullOrWhiteSpace($ansiSequence)) {
        return ('{0}{1}{2}[0m' -f $ansiSequence, $Text, [char]27)
    }

    return $Text
}

function Get-ShellForgePromptGlyph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('TopLeft', 'BottomLeft', 'Vertical', 'Horizontal', 'Check', 'Cross', 'Lightning', 'MiddleDot')]
        [string]$Name
    )

    switch ($Name) {
        'TopLeft' { return [string][char]0x256D }
        'BottomLeft' { return [string][char]0x2570 }
        'Vertical' { return [string][char]0x2502 }
        'Horizontal' { return [string][char]0x2500 }
        'Check' { return [string][char]0x2713 }
        'Cross' { return [string][char]0x2717 }
        'Lightning' { return [string][char]0x26A1 }
        'MiddleDot' { return [string][char]0x00B7 }
        default { return '' }
    }
}

function Get-ShellForgePromptWidth {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateRange(48, 160)]
        [int]$DefaultWidth = 76,

        [Parameter()]
        [ValidateRange(48, 160)]
        [int]$MaxWidth = 112
    )

    try {
        if (-not [Console]::IsOutputRedirected) {
            $windowWidth = [Console]::WindowWidth
            if ($windowWidth -gt 24) {
                return [Math]::Min($MaxWidth, [Math]::Max(48, $windowWidth - 2))
            }
        }
    }
    catch {
    }

    return $DefaultWidth
}

function New-ShellForgePromptPart {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter()]
        [string]$HexColor = ''
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $null
    }

    $styledText = $Text
    if (-not [string]::IsNullOrWhiteSpace($HexColor)) {
        $styledText = Get-ShellForgeAnsiText -Text $Text -HexColor $HexColor
    }

    return [pscustomobject]@{
        Raw    = $Text
        Styled = $styledText
    }
}

function Join-ShellForgePromptParts {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowEmptyCollection()]
        [object[]]$Parts,

        [Parameter(Mandatory)]
        [string]$Joiner,

        [Parameter()]
        [string]$JoinerHex = ''
    )

    $filteredParts = [System.Collections.Generic.List[object]]::new()
    foreach ($part in @($Parts)) {
        if ($null -eq $part) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace([string]$part.Raw)) {
            continue
        }

        [void]$filteredParts.Add($part)
    }

    if ($filteredParts.Count -eq 0) {
        return [pscustomobject]@{
            Raw    = ''
            Styled = ''
        }
    }

    $rawItems = [System.Collections.Generic.List[string]]::new()
    $styledItems = [System.Collections.Generic.List[string]]::new()
    foreach ($part in $filteredParts) {
        [void]$rawItems.Add([string]$part.Raw)
        [void]$styledItems.Add([string]$part.Styled)
    }

    $styledJoiner = $Joiner
    if (-not [string]::IsNullOrWhiteSpace($JoinerHex)) {
        $styledJoiner = Get-ShellForgeAnsiText -Text $Joiner -HexColor $JoinerHex
    }

    return [pscustomobject]@{
        Raw    = ($rawItems -join $Joiner)
        Styled = ($styledItems -join $styledJoiner)
    }
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
        if ([string]::IsNullOrWhiteSpace($branchName)) {
            return $null
        }

        $porcelainStatus = @(& git status --porcelain 2>$null)
        return [pscustomobject]@{
            Branch = $branchName
            Dirty  = ($porcelainStatus.Count -gt 0)
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

        if ($duration.TotalMinutes -ge 1) {
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

    $currentTime = [DateTime]::UtcNow
    if (($null -ne $script:ShellForgeBatteryCache) -and (($currentTime - $script:ShellForgeBatteryCacheTime).TotalSeconds -lt 30)) {
        return $script:ShellForgeBatteryCache
    }

    try {
        $battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop | Select-Object -First 1
        if ($null -eq $battery) {
            $script:ShellForgeBatteryCache = $null
            $script:ShellForgeBatteryCacheTime = $currentTime
            return $null
        }

        $script:ShellForgeBatteryCache = ('{0}%' -f [int]$battery.EstimatedChargeRemaining)
        $script:ShellForgeBatteryCacheTime = $currentTime
        return $script:ShellForgeBatteryCache
    }
    catch {
        $script:ShellForgeBatteryCache = $null
        $script:ShellForgeBatteryCacheTime = $currentTime
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

function Get-ShellForgePromptText {
    [CmdletBinding()]
    param()

    try {
        if ($null -eq $script:ShellForgeCurrentTheme) {
            return 'PS> '
        }

        $lastSuccess = $?
        $lastExitCode = $null
        $lastExitCodeVariable = Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
        if ($null -ne $lastExitCodeVariable) {
            $lastExitCode = $lastExitCodeVariable.Value
        }

        $theme = $script:ShellForgeCurrentTheme
        $useAnsi = Test-ShellForgeVirtualTerminalSupport
        $horizontal = if ($useAnsi) { Get-ShellForgePromptGlyph -Name 'Horizontal' } else { '-' }
        $topLeft = if ($useAnsi) { Get-ShellForgePromptGlyph -Name 'TopLeft' } else { '+' }
        $bottomLeft = if ($useAnsi) { Get-ShellForgePromptGlyph -Name 'BottomLeft' } else { '\' }
        $vertical = if ($useAnsi) { Get-ShellForgePromptGlyph -Name 'Vertical' } else { '|' }
        $middleDot = if ($useAnsi) { Get-ShellForgePromptGlyph -Name 'MiddleDot' } else { '|' }
        $iconEnabled = ($theme.iconDensity -ne 'None')
        $administrator = $false
        if ($theme.segments.adminEnabled) {
            $administrator = Test-ShellForgeAdministrator
        }

        $leftParts = [System.Collections.Generic.List[object]]::new()
        $rightParts = [System.Collections.Generic.List[object]]::new()
        $contextParts = [System.Collections.Generic.List[object]]::new()

        if ($theme.segments.statusEnabled) {
            $statusOk = $lastSuccess -and ($null -eq $lastExitCode -or $lastExitCode -eq 0)
            if ($statusOk) {
                $statusText = if ($iconEnabled) { Get-ShellForgePromptGlyph -Name 'Check' } else { 'OK' }
                [void]$leftParts.Add((New-ShellForgePromptPart -Text $statusText -HexColor $theme.palette.success))
            }
            else {
                $statusLabel = 'ERR'
                if ($null -ne $lastExitCode) {
                    $statusLabel = 'ERR {0}' -f $lastExitCode
                }

                $statusText = if ($iconEnabled) {
                    '{0} {1}' -f (Get-ShellForgePromptGlyph -Name 'Cross'), $statusLabel
                }
                else {
                    $statusLabel
                }

                [void]$leftParts.Add((New-ShellForgePromptPart -Text $statusText -HexColor $theme.palette.error))
            }
        }

        $currentPath = Get-ShellForgeCompactPath -PathValue (Get-Location).Path -Mode $theme.segments.pathMode
        [void]$leftParts.Add((New-ShellForgePromptPart -Text $currentPath -HexColor $theme.palette.accent))

        if ($theme.segments.gitEnabled) {
            $gitState = Get-ShellForgeGitState
            if ($null -ne $gitState) {
                $gitText = if ($gitState.Dirty) { '{0}*' -f $gitState.Branch } else { $gitState.Branch }
                [void]$leftParts.Add((New-ShellForgePromptPart -Text $gitText -HexColor $theme.palette.accentSecondary))
            }
        }

        if ($theme.segments.runtimeEnabled) {
            [void]$rightParts.Add((New-ShellForgePromptPart -Text (Get-ShellForgeRuntimeText) -HexColor $theme.palette.info))
        }

        if ($theme.segments.executionTimeEnabled) {
            $executionTime = Get-ShellForgeExecutionTime
            if ($null -ne $executionTime) {
                [void]$rightParts.Add((New-ShellForgePromptPart -Text $executionTime -HexColor $theme.palette.warning))
            }
        }

        if ($theme.segments.timeEnabled) {
            [void]$rightParts.Add((New-ShellForgePromptPart -Text ([DateTime]::Now.ToString('HH:mm')) -HexColor $theme.palette.muted))
        }

        if ($theme.segments.adminEnabled -and $administrator) {
            $adminText = 'ADMIN'
            if ($iconEnabled) {
                $adminText = '{0} ADMIN' -f (Get-ShellForgePromptGlyph -Name 'Lightning')
            }

            $adminPart = New-ShellForgePromptPart -Text $adminText -HexColor $theme.palette.warning
            if ($theme.promptLayout.lineMode -eq 'SingleLine') {
                [void]$rightParts.Add($adminPart)
            }
            else {
                [void]$contextParts.Add($adminPart)
            }
        }

        if ($theme.segments.hostEnabled) {
            $hostPart = New-ShellForgePromptPart -Text ([Environment]::MachineName) -HexColor $theme.palette.accentSecondary
            if ($theme.promptLayout.lineMode -eq 'SingleLine') {
                [void]$rightParts.Add($hostPart)
            }
            else {
                [void]$contextParts.Add($hostPart)
            }
        }

        if ($theme.segments.userEnabled) {
            $userPart = New-ShellForgePromptPart -Text ([Environment]::UserName) -HexColor $theme.palette.text
            if ($theme.promptLayout.lineMode -eq 'SingleLine') {
                [void]$rightParts.Add($userPart)
            }
            else {
                [void]$contextParts.Add($userPart)
            }
        }

        if ($theme.segments.batteryEnabled) {
            $batteryState = Get-ShellForgeBatteryState
            if ($null -ne $batteryState) {
                $batteryPart = New-ShellForgePromptPart -Text ('BAT {0}' -f $batteryState) -HexColor $theme.palette.warning
                if ($theme.promptLayout.lineMode -eq 'SingleLine') {
                    [void]$rightParts.Add($batteryPart)
                }
                else {
                    [void]$contextParts.Add($batteryPart)
                }
            }
        }

        $leftJoiner = ' ' + ($horizontal * 2) + ' '
        $rightJoiner = ' ' + $middleDot + ' '
        $contextJoiner = '  ' + $horizontal + '  '
        $borderColor = $theme.palette.muted
        $leftGroup = Join-ShellForgePromptParts -Parts @($leftParts) -Joiner $leftJoiner -JoinerHex $borderColor
        $rightGroup = Join-ShellForgePromptParts -Parts @($rightParts) -Joiner $rightJoiner -JoinerHex $borderColor
        $contextGroup = Join-ShellForgePromptParts -Parts @($contextParts) -Joiner $contextJoiner -JoinerHex $borderColor

        $topPrefixRaw = $topLeft + $horizontal + ' '
        $topPrefixStyled = if ($useAnsi) { Get-ShellForgeAnsiText -Text $topPrefixRaw -HexColor $borderColor } else { $topPrefixRaw }
        $topLine = $topPrefixStyled + $leftGroup.Styled
        if (-not [string]::IsNullOrWhiteSpace($rightGroup.Raw)) {
            $promptWidth = Get-ShellForgePromptWidth
            $consumedWidth = $topPrefixRaw.Length + $leftGroup.Raw.Length + $rightGroup.Raw.Length
            $fillerWidth = $promptWidth - $consumedWidth
            if ($fillerWidth -lt 3) {
                $fillerRaw = ' ' + $horizontal + ' '
            }
            else {
                $fillerRaw = ' ' + ($horizontal * $fillerWidth) + ' '
            }

            $fillerStyled = if ($useAnsi) { Get-ShellForgeAnsiText -Text $fillerRaw -HexColor $borderColor } else { $fillerRaw }
            $topLine = $topLine + $fillerStyled + $rightGroup.Styled
        }

        $lineParts = [System.Collections.Generic.List[string]]::new()
        [void]$lineParts.Add($topLine)

        if ($theme.promptLayout.lineMode -eq 'DoubleLine' -and -not [string]::IsNullOrWhiteSpace($contextGroup.Raw)) {
            $contextPrefixRaw = $vertical + ' '
            $contextPrefixStyled = if ($useAnsi) { Get-ShellForgeAnsiText -Text $contextPrefixRaw -HexColor $borderColor } else { $contextPrefixRaw }
            [void]$lineParts.Add($contextPrefixStyled + $contextGroup.Styled)
        }

        $promptMarker = '>'
        if ($administrator) {
            $promptMarker = '#>'
        }

        $promptPrefixRaw = $bottomLeft + ' '
        $promptPrefixStyled = if ($useAnsi) { Get-ShellForgeAnsiText -Text $promptPrefixRaw -HexColor $borderColor } else { $promptPrefixRaw }
        $promptColor = $theme.palette.text
        if ($administrator) {
            $promptColor = $theme.palette.warning
        }

        $promptMarkerStyled = if ($useAnsi) { Get-ShellForgeAnsiText -Text $promptMarker -HexColor $promptColor } else { $promptMarker }
        [void]$lineParts.Add($promptPrefixStyled + $promptMarkerStyled)

        return (($lineParts -join [Environment]::NewLine) + ' ')
    }
    catch {
        try {
            Write-ShellForgeLog -Level 'ERROR' -Operation 'Prompt' -Message $_.Exception.Message
        }
        catch {
        }

        return (Get-ShellForgeAnsiText -Text 'SF!> ' -HexColor '#FF5D7A')
    }
}
