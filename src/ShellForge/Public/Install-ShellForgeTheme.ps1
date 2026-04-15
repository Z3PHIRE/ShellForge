Set-StrictMode -Version Latest

function Install-ShellForgeTheme {
    <#
    .SYNOPSIS
    Installs a ShellForge theme locally, updates the user profile and writes a recoverable configuration.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Interactive')]
    param(
        [Parameter(ParameterSetName = 'Name', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(ParameterSetName = 'Path', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(ParameterSetName = 'Theme', Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [object]$Theme,

        [Parameter(ParameterSetName = 'Interactive')]
        [switch]$Interactive,

        [Parameter()]
        [string]$ProfilePath = $PROFILE.CurrentUserAllHosts,

        [Parameter()]
        [AllowEmptyString()]
        [string]$TerminalSettingsPath,

        [Parameter()]
        [switch]$UseOhMyPosh
    )

    process {
        $resolvedTheme = switch ($PSCmdlet.ParameterSetName) {
            'Name' { Resolve-ShellForgeTheme -Name $Name }
            'Path' { Resolve-ShellForgeTheme -Path $Path }
            'Theme' { Resolve-ShellForgeTheme -Theme $Theme }
            'Interactive' {
                $selectedTheme = Select-ShellForgeTheme -Title 'SHELLFORGE' -Subtitle 'Install a theme into your profile'
                if ($null -eq $selectedTheme) {
                    return $null
                }

                Resolve-ShellForgeTheme -Path $selectedTheme.SourcePath
            }
        }

        if ($PSCmdlet.ShouldProcess($resolvedTheme.Theme.name, 'Install ShellForge theme locally')) {
            $backupRecord = New-ShellForgeBackupRecord -ProfilePath $ProfilePath -ThemePath (Get-ShellForgePath -PathType 'CurrentTheme') -TerminalSettingsPath $TerminalSettingsPath
            $currentThemePath = Get-ShellForgePath -PathType 'CurrentTheme' -Ensure
            Write-ShellForgeJsonFile -Path $currentThemePath -Data $resolvedTheme.Theme -Depth 20
            $terminalRecommendationPath = Write-ShellForgeTerminalRecommendations -Theme $resolvedTheme.Theme
            $ohMyPoshConfigPath = ''
            if ($UseOhMyPosh.IsPresent) {
                $ohMyPoshConfigPath = New-ShellForgeOhMyPoshConfig -Theme $resolvedTheme.Theme
            }

            $profileUpdate = Set-ShellForgeProfileBlock -ThemePath $currentThemePath -ModuleManifestPath $script:ShellForgeModuleManifestPath -ProfilePath $ProfilePath -PreferOhMyPosh:$UseOhMyPosh
            Import-ShellForgeProfile -ThemePath $currentThemePath -PreferOhMyPosh:$UseOhMyPosh | Out-Null

            Write-ShellForgeLog -Level 'ACTION' -Operation 'InstallTheme' -Message ("Installed theme '{0}'." -f $resolvedTheme.Theme.name)
            return [pscustomobject]@{
                Theme                     = $resolvedTheme.Theme
                BackupId                  = $backupRecord.BackupId
                CurrentThemePath          = $currentThemePath
                ProfilePath               = $profileUpdate.ProfilePath
                LoaderPath                = $profileUpdate.LoaderPath
                TerminalRecommendationPath = $terminalRecommendationPath
                OhMyPoshConfigPath        = $ohMyPoshConfigPath
            }
        }
    }
}
