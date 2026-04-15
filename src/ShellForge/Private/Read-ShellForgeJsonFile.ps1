Set-StrictMode -Version Latest

function Read-ShellForgeJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-Path -LiteralPath $resolvedPath)) {
        throw "JSON file not found: $resolvedPath"
    }

    $rawContent = Get-Content -LiteralPath $resolvedPath -Raw -Encoding utf8
    if ([string]::IsNullOrWhiteSpace($rawContent)) {
        throw "JSON file is empty: $resolvedPath"
    }

    return $rawContent | ConvertFrom-Json -Depth 100
}

