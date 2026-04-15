Set-StrictMode -Version Latest

function Import-ShellForgeProfile {
    <#
    .SYNOPSIS
    Loads the active ShellForge theme into the current PowerShell session.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ThemePath = (Get-ShellForgePath -PathType 'CurrentTheme'),

        [Parameter()]
        [switch]$PreferOhMyPosh
    )

    $resolvedThemePath = [System.IO.Path]::GetFullPath($ThemePath)
    if (-not (Test-Path -LiteralPath $resolvedThemePath)) {
        Write-ShellForgeLog -Level 'WARN' -Operation 'ImportProfile' -Message ("Current theme file was not found: {0}" -f $resolvedThemePath)
        return $null
    }

    $resolvedTheme = Resolve-ShellForgeTheme -Path $resolvedThemePath
    $script:ShellForgeCurrentTheme = $resolvedTheme.Theme
    Set-ShellForgePSReadLine -Theme $resolvedTheme.Theme

    if ($PreferOhMyPosh.IsPresent) {
        $ohMyPoshCommand = Get-Command -Name 'oh-my-posh' -ErrorAction SilentlyContinue
        $ohMyPoshConfigPath = Get-ShellForgePath -PathType 'OhMyPosh'
        if ($null -ne $ohMyPoshCommand -and (Test-Path -LiteralPath $ohMyPoshConfigPath)) {
            $ohMyPoshExecutable = if ([string]::IsNullOrWhiteSpace($ohMyPoshCommand.Source)) { $ohMyPoshCommand.Name } else { $ohMyPoshCommand.Source }
            try {
                $initializationScript = & $ohMyPoshExecutable init pwsh --config $ohMyPoshConfigPath
                Invoke-Expression $initializationScript
                Write-ShellForgeLog -Level 'ACTION' -Operation 'ImportProfile' -Message ("Loaded theme '{0}' with Oh My Posh." -f $resolvedTheme.Theme.name)
                return $resolvedTheme.Theme
            }
            catch {
                Write-ShellForgeLog -Level 'WARN' -Operation 'ImportProfile' -Message ("Oh My Posh initialization failed. Falling back to native prompt. {0}" -f $_.Exception.Message)
            }
        }
    }

    Set-ShellForgePrompt
    Write-ShellForgeLog -Level 'ACTION' -Operation 'ImportProfile' -Message ("Loaded theme '{0}' with the native ShellForge prompt." -f $resolvedTheme.Theme.name)
    return $resolvedTheme.Theme
}

