Set-StrictMode -Version Latest

function Set-ShellForgeProfileBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ThemePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleManifestPath,

        [Parameter()]
        [string]$ProfilePath = $PROFILE.CurrentUserAllHosts,

        [Parameter()]
        [switch]$PreferOhMyPosh
    )

    $resolvedProfilePath = [System.IO.Path]::GetFullPath($ProfilePath)
    $profileDirectory = Split-Path -Path $resolvedProfilePath -Parent
    if (-not (Test-Path -LiteralPath $profileDirectory)) {
        New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
    }

    if (-not (Test-Path -LiteralPath $resolvedProfilePath)) {
        New-Item -ItemType File -Path $resolvedProfilePath -Force | Out-Null
    }

    $loaderPath = Get-ShellForgePath -PathType 'ProfileLoader' -Ensure
    $loaderArguments = if ($PreferOhMyPosh.IsPresent) { "-ThemePath '$ThemePath' -PreferOhMyPosh" } else { "-ThemePath '$ThemePath'" }
    $loaderContent = @(
        "Import-Module '$ModuleManifestPath' -ErrorAction Stop"
        "Import-ShellForgeProfile $loaderArguments"
    ) -join [Environment]::NewLine
    Set-Content -LiteralPath $loaderPath -Value $loaderContent -Encoding utf8

    $profileContent = Get-Content -LiteralPath $resolvedProfilePath -Raw -Encoding utf8
    $managedBlock = @(
        $script:ShellForgeProfileMarkerStart
        "if (Test-Path -LiteralPath '$loaderPath') {"
        "    . '$loaderPath'"
        '}'
        $script:ShellForgeProfileMarkerEnd
    ) -join [Environment]::NewLine

    $pattern = '(?ms)' + [regex]::Escape($script:ShellForgeProfileMarkerStart) + '.*?' + [regex]::Escape($script:ShellForgeProfileMarkerEnd) + '\r?\n?'
    if ($profileContent -match $pattern) {
        $updatedContent = [regex]::Replace($profileContent, $pattern, $managedBlock + [Environment]::NewLine)
    }
    elseif ([string]::IsNullOrWhiteSpace($profileContent)) {
        $updatedContent = $managedBlock + [Environment]::NewLine
    }
    else {
        $updatedContent = $profileContent.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $managedBlock + [Environment]::NewLine
    }

    Set-Content -LiteralPath $resolvedProfilePath -Value $updatedContent -Encoding utf8
    return [pscustomobject]@{
        ProfilePath = $resolvedProfilePath
        LoaderPath  = $loaderPath
    }
}

