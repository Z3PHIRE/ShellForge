Set-StrictMode -Version Latest

function Get-ShellForgeBackupManifest {
    [CmdletBinding(DefaultParameterSetName = 'Latest')]
    param(
        [Parameter(ParameterSetName = 'Id', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupId,

        [Parameter(ParameterSetName = 'Latest')]
        [switch]$Latest
    )

    $backupRoot = Get-ShellForgePath -PathType 'Backups' -Ensure
    $backupDirectories = @(Get-ChildItem -LiteralPath $backupRoot -Directory | Sort-Object -Property Name -Descending)
    if ($backupDirectories.Count -eq 0) {
        throw 'No ShellForge backup is available.'
    }

    $selectedBackup = if ($PSCmdlet.ParameterSetName -eq 'Id') {
        $backupDirectories | Where-Object { $_.Name -eq $BackupId } | Select-Object -First 1
    }
    else {
        $backupDirectories | Select-Object -First 1
    }

    if ($null -eq $selectedBackup) {
        throw "ShellForge backup '$BackupId' was not found."
    }

    $manifestPath = Join-Path -Path $selectedBackup.FullName -ChildPath 'manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Backup manifest is missing: $manifestPath"
    }

    return [pscustomobject]@{
        BackupId     = $selectedBackup.Name
        BackupPath   = $selectedBackup.FullName
        ManifestPath = $manifestPath
        Manifest     = Read-ShellForgeJsonFile -Path $manifestPath
    }
}

