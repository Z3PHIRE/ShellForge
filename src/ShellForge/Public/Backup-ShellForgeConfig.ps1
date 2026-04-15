Set-StrictMode -Version Latest

function Backup-ShellForgeConfig {
    <#
    .SYNOPSIS
    Creates a ShellForge backup before changing the PowerShell profile or theme files.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter()]
        [string]$ProfilePath = $PROFILE.CurrentUserAllHosts,

        [Parameter()]
        [string]$ThemePath = (Get-ShellForgePath -PathType 'CurrentTheme'),

        [Parameter()]
        [AllowEmptyString()]
        [string]$TerminalSettingsPath
    )

    if ($PSCmdlet.ShouldProcess('ShellForge configuration', 'Create backup')) {
        $backupRecord = New-ShellForgeBackupRecord -ProfilePath $ProfilePath -ThemePath $ThemePath -TerminalSettingsPath $TerminalSettingsPath
        Write-ShellForgeLog -Level 'ACTION' -Operation 'Backup' -Message ("Created backup '{0}'." -f $backupRecord.BackupId)
        return $backupRecord
    }
}

