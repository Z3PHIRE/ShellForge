Set-StrictMode -Version Latest

function Get-ShellForgePath {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Root', 'Config', 'Themes', 'Backups', 'Logs', 'Exports', 'LogFile', 'CurrentTheme', 'OhMyPosh', 'TerminalRecommendations', 'ProfileLoader')]
        [string]$PathType = 'Root',

        [Parameter()]
        [switch]$Ensure
    )

    $platformInfo = Get-ShellForgePlatformInfo
    switch ($platformInfo.Platform) {
        'Windows' {
            $basePath = [Environment]::GetFolderPath('LocalApplicationData')
            if ([string]::IsNullOrWhiteSpace($basePath)) {
                $basePath = $HOME
            }

            $rootPath = Join-Path -Path $basePath -ChildPath 'ShellForge'
        }
        'Linux' {
            $rootPath = Join-Path -Path (Join-Path -Path $HOME -ChildPath '.config') -ChildPath 'shellforge'
        }
        'MacOS' {
            $rootPath = Join-Path -Path (Join-Path -Path $HOME -ChildPath 'Library/Application Support') -ChildPath 'shellforge'
        }
        default {
            $rootPath = Join-Path -Path $HOME -ChildPath '.shellforge'
        }
    }

    $configPath = Join-Path -Path $rootPath -ChildPath 'config'
    $themesPath = Join-Path -Path $rootPath -ChildPath 'themes'
    $backupsPath = Join-Path -Path $rootPath -ChildPath 'backups'
    $logsPath = Join-Path -Path $rootPath -ChildPath 'logs'
    $exportsPath = Join-Path -Path $rootPath -ChildPath 'exports'

    switch ($PathType) {
        'Root' { $resolvedPath = $rootPath }
        'Config' { $resolvedPath = $configPath }
        'Themes' { $resolvedPath = $themesPath }
        'Backups' { $resolvedPath = $backupsPath }
        'Logs' { $resolvedPath = $logsPath }
        'Exports' { $resolvedPath = $exportsPath }
        'LogFile' { $resolvedPath = Join-Path -Path $logsPath -ChildPath 'shellforge.log' }
        'CurrentTheme' { $resolvedPath = Join-Path -Path $configPath -ChildPath 'current-theme.json' }
        'OhMyPosh' { $resolvedPath = Join-Path -Path $configPath -ChildPath 'shellforge.omp.json' }
        'TerminalRecommendations' { $resolvedPath = Join-Path -Path $configPath -ChildPath 'terminal-recommendations.json' }
        'ProfileLoader' { $resolvedPath = Join-Path -Path $configPath -ChildPath 'ShellForge.Profile.ps1' }
        default { throw "Unsupported path type '$PathType'." }
    }

    if ($Ensure.IsPresent) {
        $targetDirectory = if ([System.IO.Path]::HasExtension($resolvedPath)) {
            Split-Path -Path $resolvedPath -Parent
        }
        else {
            $resolvedPath
        }

        if (-not (Test-Path -LiteralPath $targetDirectory)) {
            New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
        }
    }

    return [System.IO.Path]::GetFullPath($resolvedPath)
}

