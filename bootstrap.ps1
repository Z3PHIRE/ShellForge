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

    $gitMetadataPath = Join-Path -Path $RepositoryPath -ChildPath '.git'
    if (Test-Path -LiteralPath $gitMetadataPath) {
        Write-Host 'Updating ShellForge repository...' -ForegroundColor Cyan
        Invoke-BootstrapGitCommand -Arguments @('-C', $RepositoryPath, 'fetch', 'origin', $Branch, '--prune')
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
