Set-StrictMode -Version Latest

function Add-ShellForgeZipEntryFromString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.Compression.ZipArchive]$Archive,

        [Parameter(Mandatory)]
        [string]$EntryName,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $entry = $Archive.CreateEntry($EntryName, [System.IO.Compression.CompressionLevel]::Optimal)
    $entryStream = $entry.Open()
    $utf8Encoding = [System.Text.UTF8Encoding]::new($false)
    $writer = [System.IO.StreamWriter]::new($entryStream, $utf8Encoding)
    try {
        $writer.Write($Content)
    }
    finally {
        $writer.Dispose()
        $entryStream.Dispose()
    }
}

function Add-ShellForgeZipEntryFromFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.Compression.ZipArchive]$Archive,

        [Parameter(Mandatory)]
        [string]$EntryName,

        [Parameter(Mandatory)]
        [string]$SourcePath
    )

    $entry = $Archive.CreateEntry($EntryName, [System.IO.Compression.CompressionLevel]::Optimal)
    $entryStream = $entry.Open()
    $sourceStream = [System.IO.File]::OpenRead($SourcePath)
    try {
        $sourceStream.CopyTo($entryStream)
    }
    finally {
        $sourceStream.Dispose()
        $entryStream.Dispose()
    }
}

function New-ShellForgePack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Theme,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter()]
        [AllowEmptyString()]
        [string]$PromptConfigPath
    )

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
    $outputDirectory = Split-Path -Path $resolvedOutputPath -Parent
    if (-not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    if (Test-Path -LiteralPath $resolvedOutputPath) {
        Remove-Item -LiteralPath $resolvedOutputPath -Force
    }

    $previewAssetPath = Get-ShellForgePreviewAssetPath -ThemeSlug $Theme.slug
    $packManifest = [pscustomobject]@{
        packVersion   = '1.0'
        exportedAt    = [DateTimeOffset]::UtcNow.ToString('o')
        themeName     = $Theme.name
        themeSlug     = $Theme.slug
        compatibility = $Theme.compatibility
        includedFiles = @('manifest.json', 'theme.json')
    }

    if (-not [string]::IsNullOrWhiteSpace($previewAssetPath)) {
        $packManifest.includedFiles += 'preview.svg'
    }

    if (-not [string]::IsNullOrWhiteSpace($PromptConfigPath) -and (Test-Path -LiteralPath $PromptConfigPath)) {
        $packManifest.includedFiles += 'prompt-config.json'
    }

    $fileStream = [System.IO.File]::Open($resolvedOutputPath, [System.IO.FileMode]::CreateNew)
    $archive = [System.IO.Compression.ZipArchive]::new($fileStream, [System.IO.Compression.ZipArchiveMode]::Create, $false)
    try {
        Add-ShellForgeZipEntryFromString -Archive $archive -EntryName 'manifest.json' -Content ($packManifest | ConvertTo-Json -Depth 20)
        Add-ShellForgeZipEntryFromString -Archive $archive -EntryName 'theme.json' -Content ($Theme | ConvertTo-Json -Depth 20)

        if (-not [string]::IsNullOrWhiteSpace($previewAssetPath)) {
            Add-ShellForgeZipEntryFromFile -Archive $archive -EntryName 'preview.svg' -SourcePath $previewAssetPath
        }

        if (-not [string]::IsNullOrWhiteSpace($PromptConfigPath) -and (Test-Path -LiteralPath $PromptConfigPath)) {
            Add-ShellForgeZipEntryFromFile -Archive $archive -EntryName 'prompt-config.json' -SourcePath ([System.IO.Path]::GetFullPath($PromptConfigPath))
        }
    }
    finally {
        $archive.Dispose()
        $fileStream.Dispose()
    }

    return $resolvedOutputPath
}

