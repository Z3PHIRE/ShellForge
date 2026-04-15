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

    $utf8Encoding = [System.Text.UTF8Encoding]::new($false)
    $temporaryPath = $resolvedPath + '.tmp'
    $backupPath = $resolvedPath + '.bak'

    try {
        [System.IO.File]::WriteAllText($temporaryPath, $json, $utf8Encoding)

        if (Test-Path -LiteralPath $resolvedPath) {
            try {
                [System.IO.File]::Replace($temporaryPath, $resolvedPath, $backupPath, $true)
            }
            catch {
                Move-Item -LiteralPath $temporaryPath -Destination $resolvedPath -Force
            }
        }
        else {
            [System.IO.File]::Move($temporaryPath, $resolvedPath)
        }
    }
    catch {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }

        throw
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }

        if (Test-Path -LiteralPath $backupPath) {
            Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
        }
    }
}
