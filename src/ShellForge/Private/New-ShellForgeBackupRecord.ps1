Set-StrictMode -Version Latest

function New-ShellForgeBackupRecord {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProfilePath = $PROFILE.CurrentUserAllHosts,

        [Parameter()]
        [string]$ThemePath = (Get-ShellForgePath -PathType 'CurrentTheme'),

        [Parameter()]
        [AllowEmptyString()]
        [string]$TerminalSettingsPath
    )

    $backupRoot = Get-ShellForgePath -PathType 'Backups' -Ensure
    $backupId = '{0}-{1}' -f [DateTimeOffset]::UtcNow.ToString('yyyyMMddTHHmmssZ'), ([Guid]::NewGuid().ToString('N').Substring(0, 8))
    $backupPath = Join-Path -Path $backupRoot -ChildPath $backupId
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

    $backedUpItems = [System.Collections.Generic.List[object]]::new()
    $targetItems = @(
        [pscustomobject]@{ Category = 'Profile'; SourcePath = $ProfilePath; BackupName = 'profile.ps1' },
        [pscustomobject]@{ Category = 'Theme'; SourcePath = $ThemePath; BackupName = 'current-theme.json' }
    )

    if (-not [string]::IsNullOrWhiteSpace($TerminalSettingsPath)) {
        $targetItems += [pscustomobject]@{ Category = 'TerminalSettings'; SourcePath = $TerminalSettingsPath; BackupName = 'terminal-settings.json' }
    }

    foreach ($targetItem in $targetItems) {
        if ([string]::IsNullOrWhiteSpace($targetItem.SourcePath)) {
            continue
        }

        $resolvedSourcePath = [System.IO.Path]::GetFullPath($targetItem.SourcePath)
        if (-not (Test-Path -LiteralPath $resolvedSourcePath)) {
            continue
        }

        $backupFilePath = Join-Path -Path $backupPath -ChildPath $targetItem.BackupName
        Copy-Item -LiteralPath $resolvedSourcePath -Destination $backupFilePath -Force
        [void]$backedUpItems.Add([pscustomobject]@{
            Category   = $targetItem.Category
            SourcePath = $resolvedSourcePath
            BackupPath = $backupFilePath
        })
    }

    $manifest = [pscustomobject]@{
        backupId   = $backupId
        createdAt  = [DateTimeOffset]::UtcNow.ToString('o')
        items      = @($backedUpItems)
        shellForge = [pscustomobject]@{
            profileLoaderPath          = Get-ShellForgePath -PathType 'ProfileLoader'
            terminalRecommendationPath = Get-ShellForgePath -PathType 'TerminalRecommendations'
            ohMyPoshConfigPath         = Get-ShellForgePath -PathType 'OhMyPosh'
        }
    }

    $manifestPath = Join-Path -Path $backupPath -ChildPath 'manifest.json'
    Write-ShellForgeJsonFile -Path $manifestPath -Data $manifest
    return [pscustomobject]@{
        BackupId     = $backupId
        BackupPath   = $backupPath
        ManifestPath = $manifestPath
        Manifest     = $manifest
    }
}

