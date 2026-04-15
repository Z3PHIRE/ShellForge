Set-StrictMode -Version Latest

function Restore-ShellForgeConfig {
    <#
    .SYNOPSIS
    Restores the PowerShell profile and theme files from a ShellForge backup.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Latest')]
    param(
        [Parameter(ParameterSetName = 'Id', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupId,

        [Parameter(ParameterSetName = 'Latest')]
        [switch]$Latest
    )

    $backupRecord = if ($PSCmdlet.ParameterSetName -eq 'Id') {
        Get-ShellForgeBackupManifest -BackupId $BackupId
    }
    else {
        Get-ShellForgeBackupManifest -Latest
    }

    if ($PSCmdlet.ShouldProcess($backupRecord.BackupId, 'Restore ShellForge backup')) {
        foreach ($backupItem in @($backupRecord.Manifest.items)) {
            if (-not (Test-Path -LiteralPath $backupItem.BackupPath)) {
                throw "Backup item is missing: $($backupItem.BackupPath)"
            }

            $targetDirectory = Split-Path -Path $backupItem.SourcePath -Parent
            if (-not (Test-Path -LiteralPath $targetDirectory)) {
                New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
            }

            Copy-Item -LiteralPath $backupItem.BackupPath -Destination $backupItem.SourcePath -Force
        }

        $currentThemePath = Get-ShellForgePath -PathType 'CurrentTheme'
        if (Test-Path -LiteralPath $currentThemePath) {
            Import-ShellForgeProfile -ThemePath $currentThemePath | Out-Null
        }

        Write-ShellForgeLog -Level 'ACTION' -Operation 'Restore' -Message ("Restored backup '{0}'." -f $backupRecord.BackupId)
        return $backupRecord
    }
}

