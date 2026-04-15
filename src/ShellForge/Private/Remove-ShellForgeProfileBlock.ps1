Set-StrictMode -Version Latest

function Remove-ShellForgeProfileBlock {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProfilePath = $PROFILE.CurrentUserAllHosts
    )

    $resolvedProfilePath = [System.IO.Path]::GetFullPath($ProfilePath)
    if (-not (Test-Path -LiteralPath $resolvedProfilePath)) {
        return $null
    }

    $profileContent = Get-Content -LiteralPath $resolvedProfilePath -Raw -Encoding utf8
    $pattern = '(?ms)' + [regex]::Escape($script:ShellForgeProfileMarkerStart) + '.*?' + [regex]::Escape($script:ShellForgeProfileMarkerEnd) + '\r?\n?'
    $updatedContent = [regex]::Replace($profileContent, $pattern, '')
    Set-Content -LiteralPath $resolvedProfilePath -Value ($updatedContent.TrimEnd() + [Environment]::NewLine) -Encoding utf8

    $loaderPath = Get-ShellForgePath -PathType 'ProfileLoader'
    if (Test-Path -LiteralPath $loaderPath) {
        Remove-Item -LiteralPath $loaderPath -Force
    }

    return $resolvedProfilePath
}

