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
    $escapedThemePath = $ThemePath.Replace("'", "''")
    $escapedModuleManifestPath = $ModuleManifestPath.Replace("'", "''")
    $loaderArguments = if ($PreferOhMyPosh.IsPresent) { "Import-ShellForgeProfile -ThemePath '$escapedThemePath' -PreferOhMyPosh" } else { "Import-ShellForgeProfile -ThemePath '$escapedThemePath'" }
    $loaderContent = @(
        "`$shellForgeModuleManifestPath = '$escapedModuleManifestPath'"
        "if (Test-Path -LiteralPath `$shellForgeModuleManifestPath) {"
        "    Import-Module `$shellForgeModuleManifestPath -ErrorAction Stop"
        '}'
        'else {'
        "    Import-Module ShellForge -ErrorAction Stop"
        '}'
        $loaderArguments
    ) -join [Environment]::NewLine
    [System.IO.File]::WriteAllText($loaderPath, $loaderContent, [System.Text.UTF8Encoding]::new($false))

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

    [System.IO.File]::WriteAllText($resolvedProfilePath, $updatedContent, [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{
        ProfilePath = $resolvedProfilePath
        LoaderPath  = $loaderPath
    }
}
