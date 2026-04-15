param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RepositoryUrl = 'https://github.com/Z3PHIRE/ShellForge.git',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Branch = 'main',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$InstallRoot = $HOME,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RepositoryName = 'ShellForge',

    [Parameter()]
    [switch]$SkipImport,

    [Parameter()]
    [switch]$SkipGit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-BootstrapPlatformInfo {
    [CmdletBinding()]
    param()

    $platform = 'Windows'
    $runtimeInformationType = [System.Type]::GetType('System.Runtime.InteropServices.RuntimeInformation, System.Runtime.InteropServices.RuntimeInformation')
    if ($null -ne $runtimeInformationType) {
        if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
            $platform = 'Windows'
        }
        elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)) {
            $platform = 'Linux'
        }
        elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) {
            $platform = 'MacOS'
        }
        else {
            $platform = 'Unknown'
        }
    }

    return [pscustomobject]@{
        Platform  = $platform
        PSEdition = [string]$PSVersionTable.PSEdition
        PSVersion = [string]$PSVersionTable.PSVersion
    }
}

function Invoke-BootstrapGit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RepositoryPath
    )

    $gitCommand = Get-Command -Name git -ErrorAction SilentlyContinue
    if ($null -eq $gitCommand) {
        throw 'Git is required to install or update ShellForge.'
    }

    function Invoke-BootstrapGitCommand {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string[]]$Arguments
        )

        $previousErrorActionPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            & $gitCommand.Source @Arguments | Out-Host
            $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }

        if ($exitCode -ne 0) {
            throw ("Git command failed with exit code {0}: git {1}" -f $exitCode, ($Arguments -join ' '))
        }
    }

    function Invoke-BootstrapGitQuery {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [string[]]$Arguments
        )

        $previousErrorActionPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = 'Continue'
            $output = & $gitCommand.Source @Arguments 2>&1
            $exitCode = $LASTEXITCODE
        }
        finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }

        if ($exitCode -ne 0) {
            throw ("Git command failed with exit code {0}: git {1}" -f $exitCode, ($Arguments -join ' '))
        }

        return @($output | ForEach-Object { [string]$_ })
    }

    function Protect-BootstrapWorkingTree {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [string]$WorkingRepositoryPath
        )

        $generatedArtifactPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        [void]$generatedArtifactPaths.Add('ShellForge.Diagnostics.Report.json')

        $statusLines = @(Invoke-BootstrapGitQuery -Arguments @('-C', $WorkingRepositoryPath, 'status', '--porcelain', '--untracked-files=no'))
        if ($statusLines.Count -eq 0) {
            return
        }

        $restorablePaths = [System.Collections.Generic.List[string]]::new()
        $unsafePaths = [System.Collections.Generic.List[string]]::new()

        foreach ($statusLine in $statusLines) {
            if ([string]::IsNullOrWhiteSpace($statusLine)) {
                continue
            }

            if ($statusLine.Length -lt 4) {
                continue
            }

            $pathText = $statusLine.Substring(3).Trim()
            if ([string]::IsNullOrWhiteSpace($pathText)) {
                continue
            }

            if ($pathText.Contains(' -> ')) {
                $pathText = ($pathText.Split(' -> ')[-1]).Trim()
            }

            if ($generatedArtifactPaths.Contains($pathText)) {
                [void]$restorablePaths.Add($pathText)
            }
            else {
                [void]$unsafePaths.Add($pathText)
            }
        }

        if ($unsafePaths.Count -gt 0) {
            throw ('ShellForge update stopped because local changes were detected: {0}. Commit, stash, or restore these files, then rerun bootstrap.' -f ($unsafePaths -join ', '))
        }

        foreach ($restorablePath in $restorablePaths) {
            Write-Host ("Restoring generated ShellForge artifact before update: {0}" -f $restorablePath) -ForegroundColor Yellow
            try {
                Invoke-BootstrapGitCommand -Arguments @('-C', $WorkingRepositoryPath, 'restore', '--source=HEAD', '--worktree', '--', $restorablePath)
            }
            catch {
                Invoke-BootstrapGitCommand -Arguments @('-C', $WorkingRepositoryPath, 'checkout', '--', $restorablePath)
            }
        }
    }

    $gitMetadataPath = Join-Path -Path $RepositoryPath -ChildPath '.git'
    if (Test-Path -LiteralPath $gitMetadataPath) {
        Write-Host 'Updating ShellForge repository...' -ForegroundColor Cyan
        Invoke-BootstrapGitCommand -Arguments @('-C', $RepositoryPath, 'fetch', 'origin', $Branch, '--prune')
        Protect-BootstrapWorkingTree -WorkingRepositoryPath $RepositoryPath
        Invoke-BootstrapGitCommand -Arguments @('-C', $RepositoryPath, 'checkout', $Branch)
        Invoke-BootstrapGitCommand -Arguments @('-C', $RepositoryPath, 'merge', '--ff-only', ('origin/{0}' -f $Branch))
        return 'Updated'
    }

    if (Test-Path -LiteralPath $RepositoryPath) {
        throw "The target path already exists and is not a Git repository: $RepositoryPath"
    }

    Write-Host 'Cloning ShellForge repository...' -ForegroundColor Cyan
    Invoke-BootstrapGitCommand -Arguments @('clone', '--branch', $Branch, $RepositoryUrl, $RepositoryPath)
    return 'Cloned'
}

$resolvedInstallRoot = [System.IO.Path]::GetFullPath($InstallRoot)
if (-not (Test-Path -LiteralPath $resolvedInstallRoot)) {
    New-Item -ItemType Directory -Path $resolvedInstallRoot -Force | Out-Null
}

$repositoryPath = [System.IO.Path]::GetFullPath((Join-Path -Path $resolvedInstallRoot -ChildPath $RepositoryName))
$moduleManifestPath = Join-Path -Path $repositoryPath -ChildPath 'src\ShellForge\ShellForge.psd1'

if (-not $SkipGit.IsPresent) {
    $operationResult = Invoke-BootstrapGit -RepositoryPath $repositoryPath
}
else {
    $operationResult = 'Skipped'
}

if (-not (Test-Path -LiteralPath $moduleManifestPath)) {
    throw "The ShellForge module manifest was not found: $moduleManifestPath"
}

$platformInfo = Get-BootstrapPlatformInfo
if ($platformInfo.Platform -eq 'Windows') {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}

if (-not $SkipImport.IsPresent) {
    Import-Module $moduleManifestPath -Force
}

Write-Host ''
Write-Host 'ShellForge is ready.' -ForegroundColor Green
Write-Host ('Repository: {0}' -f $repositoryPath) -ForegroundColor Gray
Write-Host ('Result: {0}' -f $operationResult) -ForegroundColor Gray
Write-Host ''
Write-Host 'Next commands:' -ForegroundColor Cyan
Write-Host ('  Set-Location "{0}"' -f $repositoryPath) -ForegroundColor White
Write-Host ('  Import-Module "{0}" -Force' -f $moduleManifestPath) -ForegroundColor White
Write-Host '  Get-Command -Module ShellForge' -ForegroundColor White
Write-Host '  Get-ShellForgeTheme' -ForegroundColor White
Write-Host '  shellforge' -ForegroundColor White
