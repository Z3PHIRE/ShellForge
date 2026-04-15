[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(5, 120)]
    [int]$InteractiveTimeoutSeconds = 25,

    [Parameter()]
    [switch]$SkipInteractive,

    [Parameter()]
    [switch]$KeepArtifacts,

    [Parameter()]
    [string]$ReportPath = '',

    [Parameter()]
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $PSScriptRoot
}
else {
    Split-Path -Path $MyInvocation.MyCommand.Path -Parent
}

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = ''
}

function ConvertTo-DiagnosticText {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return ''
    }

    if ($InputObject -is [string]) {
        return $InputObject
    }

    return (($InputObject | Out-String).Trim())
}

function Get-DiagnosticDefaultReportPath {
    [CmdletBinding()]
    param()

    $baseDirectory = ''
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $baseDirectory = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'ShellForge\diagnostics'
    }
    elseif (-not [string]::IsNullOrWhiteSpace($HOME)) {
        $baseDirectory = Join-Path -Path $HOME -ChildPath '.shellforge\diagnostics'
    }
    else {
        $baseDirectory = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath 'ShellForge\diagnostics'
    }

    if (-not (Test-Path -LiteralPath $baseDirectory)) {
        New-Item -ItemType Directory -Path $baseDirectory -Force | Out-Null
    }

    return (Join-Path -Path $baseDirectory -ChildPath 'ShellForge.Diagnostics.Report.json')
}

function Get-DiagnosticPromptScriptBlock {
    [CmdletBinding()]
    param()

    $promptCommand = Get-Command -Name prompt -CommandType Function -ErrorAction SilentlyContinue
    if ($null -eq $promptCommand) {
        return $null
    }

    return $promptCommand.ScriptBlock
}

function Get-DiagnosticDefaultPromptScriptBlock {
    [CmdletBinding()]
    param()

    return {
        'PS {0}{1} ' -f (Get-Location), ('>' * ($nestedPromptLevel + 1))
    }
}

function Restore-DiagnosticPrompt {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [scriptblock]$PromptScriptBlock
    )

    if ($null -eq $PromptScriptBlock) {
        if (Test-Path -LiteralPath 'Function:\global:prompt') {
            Remove-Item -LiteralPath 'Function:\global:prompt' -Force -ErrorAction SilentlyContinue
        }

        return
    }

    Set-Item -Path 'Function:\global:prompt' -Value $PromptScriptBlock
}

function Get-DiagnosticPSReadLineState {
    [CmdletBinding()]
    param()

    $getPSReadLineOptionCommand = Get-Command -Name Get-PSReadLineOption -ErrorAction SilentlyContinue
    if ($null -eq $getPSReadLineOptionCommand) {
        return $null
    }

    try {
        $psReadLineOptions = Get-PSReadLineOption
    }
    catch {
        return $null
    }

    $colorTable = @{}
    if ($psReadLineOptions.PSObject.Properties.Name -contains 'Colors' -and $null -ne $psReadLineOptions.Colors) {
        foreach ($colorEntry in $psReadLineOptions.Colors.GetEnumerator()) {
            $colorTable[[string]$colorEntry.Key] = [string]$colorEntry.Value
        }
    }

    return [pscustomobject]@{
        EditMode = [string]$psReadLineOptions.EditMode
        Colors   = $colorTable
    }
}

function Restore-DiagnosticPSReadLineState {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [pscustomobject]$State
    )

    if ($null -eq $State) {
        return
    }

    $setPSReadLineOptionCommand = Get-Command -Name Set-PSReadLineOption -ErrorAction SilentlyContinue
    if ($null -eq $setPSReadLineOptionCommand) {
        return
    }

    try {
        Set-PSReadLineOption -EditMode $State.EditMode
    }
    catch {
    }

    foreach ($colorKey in @($State.Colors.Keys)) {
        try {
            Set-PSReadLineOption -Colors @{ $colorKey = $State.Colors[$colorKey] }
        }
        catch {
        }
    }
}

function New-DiagnosticFileSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $resolvedPath)) {
        return [pscustomobject]@{
            Path     = $resolvedPath
            Exists   = $false
            Contents = @()
        }
    }

    return [pscustomobject]@{
        Path     = $resolvedPath
        Exists   = $true
        Contents = [System.IO.File]::ReadAllBytes($resolvedPath)
    }
}

function Restore-DiagnosticFileSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Snapshot
    )

    $resolvedPath = [System.IO.Path]::GetFullPath($Snapshot.Path)
    if ($Snapshot.Exists) {
        $targetDirectory = Split-Path -Path $resolvedPath -Parent
        if (-not (Test-Path -LiteralPath $targetDirectory)) {
            New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
        }

        [System.IO.File]::WriteAllBytes($resolvedPath, $Snapshot.Contents)
        return
    }

    if (Test-Path -LiteralPath $resolvedPath) {
        Remove-Item -LiteralPath $resolvedPath -Force -ErrorAction SilentlyContinue
    }
}

function Get-DiagnosticModuleInternalPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('CurrentTheme', 'OhMyPosh', 'TerminalRecommendations', 'ProfileLoader', 'Backups')]
        [string]$PathType
    )

    $shellForgeModule = Get-Module -Name ShellForge
    if ($null -eq $shellForgeModule) {
        throw 'ShellForge must be imported before reading internal paths.'
    }

    return (& $shellForgeModule {
        param(
            [Parameter(Mandatory)]
            [string]$InnerPathType
        )

        Get-ShellForgePath -PathType $InnerPathType -Ensure
    } $PathType)
}

function Invoke-DiagnosticInteractiveMenuTest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleManifestPath,

        [Parameter(Mandatory)]
        [ValidateRange(5, 120)]
        [int]$TimeoutSeconds
    )

    $hostExecutablePath = (Get-Process -Id $PID).Path
    $processStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $processStartInfo.FileName = $hostExecutablePath
    $processStartInfo.WorkingDirectory = $PSScriptRoot
    $processStartInfo.UseShellExecute = $false
    $processStartInfo.RedirectStandardInput = $true
    $processStartInfo.RedirectStandardOutput = $true
    $processStartInfo.RedirectStandardError = $true

    if ($hostExecutablePath -like '*pwsh*') {
        $processStartInfo.Arguments = ('-NoProfile -Command "Import-Module ''{0}'' -Force; shellforge; exit 0"' -f $ModuleManifestPath)
    }
    else {
        $processStartInfo.Arguments = ('-NoProfile -ExecutionPolicy Bypass -Command "Import-Module ''{0}'' -Force; shellforge; exit 0"' -f $ModuleManifestPath)
    }

    $process = [System.Diagnostics.Process]::Start($processStartInfo)
    try {
        $process.StandardInput.WriteLine('')
        $process.StandardInput.WriteLine('3')
        $process.StandardInput.WriteLine('')
        $process.StandardInput.WriteLine('0')
        $process.StandardInput.Close()

        $timedOut = $false
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $timedOut = $true
            $process.Kill()
            $process.WaitForExit()
        }

        $standardOutput = $process.StandardOutput.ReadToEnd()
        $standardError = $process.StandardError.ReadToEnd()

        if (-not $timedOut -and $process.ExitCode -ne 0) {
            throw ("Interactive menu test failed with exit code {0}.{1}{2}" -f $process.ExitCode, [Environment]::NewLine, $standardError)
        }

        if (-not [string]::IsNullOrWhiteSpace($standardError)) {
            throw ("Interactive menu wrote to standard error:{0}{1}" -f [Environment]::NewLine, $standardError.Trim())
        }

        $interactiveErrorPatterns = @(
            'Read-ShellForgeMenuSelection\s*:'
            'PropertyNotFoundException'
            'FullyQualifiedErrorId'
            'CategoryInfo'
            'Exception'
        )

        foreach ($interactiveErrorPattern in $interactiveErrorPatterns) {
            if ($standardOutput -match $interactiveErrorPattern) {
                throw ("Interactive menu output contains an error pattern '{0}'.{1}{2}" -f $interactiveErrorPattern, [Environment]::NewLine, $standardOutput.Trim())
            }
        }

        if ($timedOut) {
            $expectedOutputPatterns = @(
                'Interactive theme menu'
                'Theme preview'
                'Theme is valid:'
            )

            foreach ($expectedOutputPattern in $expectedOutputPatterns) {
                if ($standardOutput -notmatch $expectedOutputPattern) {
                    throw "Interactive menu test timed out before the expected output was fully observed."
                }
            }
        }

        return [pscustomobject]@{
            ExitCode       = if ($timedOut) { 0 } else { $process.ExitCode }
            TimedOut       = $timedOut
            StandardOutput = $standardOutput
            StandardError  = $standardError
        }
    }
    finally {
        if (-not $process.HasExited) {
            $process.Kill()
        }

        $process.Dispose()
    }
}

function Invoke-DiagnosticStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[object]]$Results
    )

    Write-Host ''
    Write-Host ('[RUN] {0}' -f $Name) -ForegroundColor Cyan

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $stepOutput = & $ScriptBlock
        $stopwatch.Stop()

        $stepText = ConvertTo-DiagnosticText -InputObject $stepOutput
        if (-not [string]::IsNullOrWhiteSpace($stepText)) {
            Write-Host $stepText -ForegroundColor Gray
        }

        [void]$Results.Add([pscustomobject]@{
            Name           = $Name
            Status         = 'Passed'
            DurationMs     = [int]$stopwatch.ElapsedMilliseconds
            Output         = $stepText
            ErrorMessage   = ''
            ExceptionType  = ''
        })

        Write-Host ('[OK] {0}' -f $Name) -ForegroundColor Green
    }
    catch {
        $stopwatch.Stop()
        $errorText = ConvertTo-DiagnosticText -InputObject $_
        [void]$Results.Add([pscustomobject]@{
            Name           = $Name
            Status         = 'Failed'
            DurationMs     = [int]$stopwatch.ElapsedMilliseconds
            Output         = ''
            ErrorMessage   = $errorText
            ExceptionType  = $_.Exception.GetType().FullName
        })

        Write-Host ('[ERROR] {0}' -f $Name) -ForegroundColor Red
        Write-Host $errorText -ForegroundColor Yellow
    }
}

$moduleManifestPath = [System.IO.Path]::GetFullPath((Join-Path -Path $scriptRoot -ChildPath 'src\ShellForge\ShellForge.psd1'))
if (-not (Test-Path -LiteralPath $moduleManifestPath)) {
    throw "ShellForge module manifest not found: $moduleManifestPath"
}

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Get-DiagnosticDefaultReportPath
}

$results = [System.Collections.Generic.List[object]]::new()
$artifactsRoot = [System.IO.Path]::GetFullPath((Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('ShellForge-Diagnostic-' + ([Guid]::NewGuid().ToString('N')))))
New-Item -ItemType Directory -Path $artifactsRoot -Force | Out-Null

$tempProfileInstallPath = Join-Path -Path $artifactsRoot -ChildPath 'install-profile.ps1'
$tempProfileRestorePath = Join-Path -Path $artifactsRoot -ChildPath 'restore-profile.ps1'
$tempThemeRestorePath = Join-Path -Path $artifactsRoot -ChildPath 'restore-theme.json'

$initialLocation = (Get-Location).Path
$initialPrompt = Get-DiagnosticPromptScriptBlock
$defaultPrompt = Get-DiagnosticDefaultPromptScriptBlock
$initialPSReadLineState = Get-DiagnosticPSReadLineState
$moduleWasLoadedBeforeDiagnostic = ($null -ne (Get-Module -Name ShellForge))

$currentThemeSnapshot = $null
$ohMyPoshSnapshot = $null
$terminalRecommendationSnapshot = $null
$profileLoaderSnapshot = $null
$backupRootPath = ''
$existingBackupDirectories = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$generatedTheme = $null
$backupRecord = $null
$installRecord = $null

try {
    Invoke-DiagnosticStep -Name 'Import module' -Results $results -ScriptBlock {
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
        }

        Import-Module $moduleManifestPath -Force
        'Module imported successfully.'
    }

    $currentThemePath = Get-DiagnosticModuleInternalPath -PathType 'CurrentTheme'
    $ohMyPoshPath = Get-DiagnosticModuleInternalPath -PathType 'OhMyPosh'
    $terminalRecommendationPath = Get-DiagnosticModuleInternalPath -PathType 'TerminalRecommendations'
    $profileLoaderPath = Get-DiagnosticModuleInternalPath -PathType 'ProfileLoader'
    $backupRootPath = Get-DiagnosticModuleInternalPath -PathType 'Backups'

    $currentThemeSnapshot = New-DiagnosticFileSnapshot -Path $currentThemePath
    $ohMyPoshSnapshot = New-DiagnosticFileSnapshot -Path $ohMyPoshPath
    $terminalRecommendationSnapshot = New-DiagnosticFileSnapshot -Path $terminalRecommendationPath
    $profileLoaderSnapshot = New-DiagnosticFileSnapshot -Path $profileLoaderPath

    if (Test-Path -LiteralPath $backupRootPath) {
        foreach ($backupDirectory in @(Get-ChildItem -LiteralPath $backupRootPath -Directory)) {
            [void]$existingBackupDirectories.Add($backupDirectory.Name)
        }
    }

    Invoke-DiagnosticStep -Name 'List public commands' -Results $results -ScriptBlock {
        (Get-Command -Module ShellForge | Select-Object -ExpandProperty Name) -join ', '
    }

    Invoke-DiagnosticStep -Name 'List built-in themes' -Results $results -ScriptBlock {
        (Get-ShellForgeTheme | Select-Object -ExpandProperty Name) -join ', '
    }

    Invoke-DiagnosticStep -Name 'Validate all themes' -Results $results -ScriptBlock {
        $validationResults = @(Test-ShellForgeTheme)
        $invalidThemes = @($validationResults | Where-Object { -not $_.IsValid })
        if ($invalidThemes.Count -gt 0) {
            throw ('Invalid themes: {0}' -f (($invalidThemes | Select-Object -ExpandProperty ThemeName) -join ', '))
        }

        ('Validated {0} themes.' -f $validationResults.Count)
    }

    Invoke-DiagnosticStep -Name 'Get theme by name' -Results $results -ScriptBlock {
        $theme = Get-ShellForgeTheme -Name 'CyberGlass'
        ('Theme loaded: {0} ({1})' -f $theme.Name, $theme.Slug)
    }

    Invoke-DiagnosticStep -Name 'Get theme by path' -Results $results -ScriptBlock {
        $themePath = Join-Path -Path $scriptRoot -ChildPath 'themes\amber-soc.json'
        $theme = Get-ShellForgeTheme -Path $themePath
        ('Theme loaded from path: {0}' -f $theme.Name)
    }

    Invoke-DiagnosticStep -Name 'Apply theme by name' -Results $results -ScriptBlock {
        $theme = Use-ShellForgeTheme -Name 'CyberGlass'
        ('Applied theme: {0}' -f $theme.Name)
    }

    Invoke-DiagnosticStep -Name 'Apply theme by path' -Results $results -ScriptBlock {
        $themePath = Join-Path -Path $scriptRoot -ChildPath 'themes\amber-soc.json'
        $theme = Use-ShellForgeTheme -Path $themePath
        ('Applied theme from path: {0}' -f $theme.Name)
    }

    Invoke-DiagnosticStep -Name 'Create custom theme object' -Results $results -ScriptBlock {
        $script:generatedTheme = New-ShellForgeTheme -Name 'Diagnostic Forge' -Description 'Diagnostic test theme' -PaletteName Graphite -PromptStyle PathHeavy -Density Medium -LineMode SingleLine -IconDensity Low -PathMode Short
        ('Generated theme: {0}' -f $script:generatedTheme.Name)
    }

    Invoke-DiagnosticStep -Name 'Validate generated theme' -Results $results -ScriptBlock {
        $validationResult = Test-ShellForgeTheme -Theme $script:generatedTheme
        if (-not $validationResult.IsValid) {
            throw ($validationResult.Errors -join [Environment]::NewLine)
        }

        ('Generated theme is valid: {0}' -f $script:generatedTheme.Name)
    }

    Invoke-DiagnosticStep -Name 'Create backup and restore temp files' -Results $results -ScriptBlock {
        Set-Content -LiteralPath $tempProfileRestorePath -Value 'Write-Host ''before-restore''' -Encoding utf8
        Copy-Item -LiteralPath (Join-Path -Path $scriptRoot -ChildPath 'themes\cyberglass.json') -Destination $tempThemeRestorePath -Force

        $script:backupRecord = Backup-ShellForgeConfig -ProfilePath $tempProfileRestorePath -ThemePath $tempThemeRestorePath
        Set-Content -LiteralPath $tempProfileRestorePath -Value 'Write-Host ''after-backup''' -Encoding utf8
        Set-Content -LiteralPath $tempThemeRestorePath -Value '{}' -Encoding utf8

        Restore-ShellForgeConfig -BackupId $script:backupRecord.BackupId | Out-Null

        $restoredProfileContent = Get-Content -LiteralPath $tempProfileRestorePath -Raw -Encoding utf8
        if ($restoredProfileContent -notmatch 'before-restore') {
            throw 'Temp profile content was not restored correctly.'
        }

        $restoredThemeContent = Get-Content -LiteralPath $tempThemeRestorePath -Raw -Encoding utf8
        if ($restoredThemeContent -notmatch 'CyberGlass') {
            throw 'Temp theme content was not restored correctly.'
        }

        ('Backup and restore succeeded with backup id {0}.' -f $script:backupRecord.BackupId)
    }

    Invoke-DiagnosticStep -Name 'Install theme into temp profile' -Results $results -ScriptBlock {
        $script:installRecord = Install-ShellForgeTheme -Name 'Arctic Void' -ProfilePath $tempProfileInstallPath
        if (-not (Test-Path -LiteralPath $tempProfileInstallPath)) {
            throw 'Temp install profile was not created.'
        }

        $profileContent = Get-Content -LiteralPath $tempProfileInstallPath -Raw -Encoding utf8
        if ($profileContent -notmatch 'ShellForge Managed Block') {
            throw 'ShellForge managed block was not written to the temp profile.'
        }

        ('Installed theme: {0}' -f $script:installRecord.Theme.Name)
    }

    Invoke-DiagnosticStep -Name 'Import current ShellForge profile theme' -Results $results -ScriptBlock {
        $importedTheme = Import-ShellForgeProfile
        if ($null -eq $importedTheme) {
            throw 'Import-ShellForgeProfile did not return a theme.'
        }

        ('Imported theme: {0}' -f $importedTheme.Name)
    }

    if (-not $SkipInteractive.IsPresent) {
        Invoke-DiagnosticStep -Name 'Run interactive menu smoke test' -Results $results -ScriptBlock {
            $interactiveResult = Invoke-DiagnosticInteractiveMenuTest -ModuleManifestPath $moduleManifestPath -TimeoutSeconds $InteractiveTimeoutSeconds
            if ($interactiveResult.StandardOutput -notmatch 'Theme preview') {
                throw 'Interactive menu output did not contain the expected preview text.'
            }

            'Interactive menu completed successfully.'
        }
    }
}
finally {
    if ($null -ne $profileLoaderSnapshot) {
        Restore-DiagnosticFileSnapshot -Snapshot $profileLoaderSnapshot
    }

    if ($null -ne $terminalRecommendationSnapshot) {
        Restore-DiagnosticFileSnapshot -Snapshot $terminalRecommendationSnapshot
    }

    if ($null -ne $ohMyPoshSnapshot) {
        Restore-DiagnosticFileSnapshot -Snapshot $ohMyPoshSnapshot
    }

    if ($null -ne $currentThemeSnapshot) {
        Restore-DiagnosticFileSnapshot -Snapshot $currentThemeSnapshot
    }

    if (-not [string]::IsNullOrWhiteSpace($backupRootPath) -and (Test-Path -LiteralPath $backupRootPath)) {
        foreach ($backupDirectory in @(Get-ChildItem -LiteralPath $backupRootPath -Directory)) {
            if (-not $existingBackupDirectories.Contains($backupDirectory.Name)) {
                $resolvedBackupPath = [System.IO.Path]::GetFullPath($backupDirectory.FullName)
                if ($resolvedBackupPath.StartsWith([System.IO.Path]::GetFullPath($backupRootPath), [System.StringComparison]::OrdinalIgnoreCase)) {
                    Remove-Item -LiteralPath $resolvedBackupPath -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Restore-DiagnosticPSReadLineState -State $initialPSReadLineState
    Set-Location -Path $initialLocation

    if ($null -ne (Get-Module -Name ShellForge)) {
        Remove-Module -Name ShellForge -Force -ErrorAction SilentlyContinue
    }

    Restore-DiagnosticPrompt -PromptScriptBlock $defaultPrompt

    if (-not $KeepArtifacts.IsPresent -and (Test-Path -LiteralPath $artifactsRoot)) {
        Remove-Item -LiteralPath $artifactsRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$resolvedReportPath = [System.IO.Path]::GetFullPath($ReportPath)
$reportDirectoryPath = Split-Path -Path $resolvedReportPath -Parent
if (-not [string]::IsNullOrWhiteSpace($reportDirectoryPath) -and -not (Test-Path -LiteralPath $reportDirectoryPath)) {
    New-Item -ItemType Directory -Path $reportDirectoryPath -Force | Out-Null
}

$summary = [pscustomobject]@{
    generatedAtUtc = [DateTimeOffset]::UtcNow.ToString('o')
    repositoryRoot = $scriptRoot
    reportPath     = $resolvedReportPath
    totalSteps     = $results.Count
    passedSteps    = @($results | Where-Object { $_.Status -eq 'Passed' }).Count
    failedSteps    = @($results | Where-Object { $_.Status -eq 'Failed' }).Count
    keepArtifacts  = [bool]$KeepArtifacts
    results        = @($results)
}

$summaryJson = $summary | ConvertTo-Json -Depth 10
Set-Content -LiteralPath $resolvedReportPath -Value $summaryJson -Encoding utf8

Write-Host ''
Write-Host '============================================================' -ForegroundColor DarkGray
Write-Host ' SHELLFORGE DIAGNOSTICS SUMMARY' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor DarkGray
Write-Host ('Passed: {0}' -f $summary.passedSteps) -ForegroundColor Green
Write-Host ('Failed: {0}' -f $summary.failedSteps) -ForegroundColor $(if ($summary.failedSteps -gt 0) { 'Red' } else { 'Green' })
Write-Host ('Report: {0}' -f $summary.reportPath) -ForegroundColor Gray

if ($summary.failedSteps -gt 0) {
    Write-Host ''
    Write-Host 'Failed steps:' -ForegroundColor Yellow
    foreach ($failedResult in @($results | Where-Object { $_.Status -eq 'Failed' })) {
        Write-Host (' - {0}' -f $failedResult.Name) -ForegroundColor Yellow
        Write-Host ('   {0}' -f $failedResult.ErrorMessage) -ForegroundColor DarkYellow
    }
}
else {
    Write-Host 'All diagnostic steps completed successfully.' -ForegroundColor Green
}

if ($PassThru.IsPresent) {
    return $summary
}
