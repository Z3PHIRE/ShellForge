Set-StrictMode -Version Latest

function Write-ShellForgeJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Data,

        [Parameter()]
        [ValidateRange(2, 100)]
        [int]$Depth = 12
    )

    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $targetDirectory = Split-Path -Path $resolvedPath -Parent
    if (-not (Test-Path -LiteralPath $targetDirectory)) {
        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    }

    $isEnumerable = ($Data -is [System.Collections.IEnumerable]) -and -not ($Data -is [string]) -and -not ($Data -is [pscustomobject]) -and -not ($Data -is [hashtable])
    $json = if ($isEnumerable) {
        @($Data) | ConvertTo-Json -Depth $Depth
    }
    else {
        $Data | ConvertTo-Json -Depth $Depth
    }

    Set-Content -LiteralPath $resolvedPath -Value $json -Encoding utf8
}

