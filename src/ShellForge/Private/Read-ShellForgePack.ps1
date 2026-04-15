Set-StrictMode -Version Latest

function Read-ShellForgePack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $resolvedPackPath = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $resolvedPackPath)) {
        throw "ShellForge pack was not found: $resolvedPackPath"
    }

    $fileStream = [System.IO.File]::OpenRead($resolvedPackPath)
    $archive = [System.IO.Compression.ZipArchive]::new($fileStream, [System.IO.Compression.ZipArchiveMode]::Read, $false)
    try {
        $entries = @($archive.Entries)
        foreach ($entry in $entries) {
            if ($entry.FullName -match '(^[/\\])|(\.\.)|(:)') {
                throw "ShellForge pack contains an unsafe entry name: $($entry.FullName)"
            }
        }

        $manifestEntry = $entries | Where-Object { $_.FullName -eq 'manifest.json' } | Select-Object -First 1
        $themeEntry = $entries | Where-Object { $_.FullName -eq 'theme.json' } | Select-Object -First 1
        if ($null -eq $manifestEntry -or $null -eq $themeEntry) {
            throw 'ShellForge pack is malformed. Required files manifest.json and theme.json are missing.'
        }

        $readEntry = {
            param([System.IO.Compression.ZipArchiveEntry]$ZipEntry)
            $entryStream = $ZipEntry.Open()
            $reader = [System.IO.StreamReader]::new($entryStream, [System.Text.UTF8Encoding]::new($false))
            try {
                return $reader.ReadToEnd()
            }
            finally {
                $reader.Dispose()
                $entryStream.Dispose()
            }
        }

        $manifestContent = & $readEntry $manifestEntry
        $themeContent = & $readEntry $themeEntry
        $previewEntry = $entries | Where-Object { $_.FullName -eq 'preview.svg' } | Select-Object -First 1
        $promptConfigEntry = $entries | Where-Object { $_.FullName -eq 'prompt-config.json' } | Select-Object -First 1

        $previewContent = if ($null -ne $previewEntry) { & $readEntry $previewEntry } else { '' }
        $promptConfigContent = if ($null -ne $promptConfigEntry) { & $readEntry $promptConfigEntry } else { '' }

        return [pscustomobject]@{
            PackPath            = $resolvedPackPath
            Manifest            = ($manifestContent | ConvertFrom-Json)
            Theme               = (ConvertTo-ShellForgeThemeObject -InputObject ($themeContent | ConvertFrom-Json))
            PreviewContent      = $previewContent
            PromptConfigContent = $promptConfigContent
        }
    }
    finally {
        $archive.Dispose()
        $fileStream.Dispose()
    }
}
