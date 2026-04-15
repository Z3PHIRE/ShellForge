Set-StrictMode -Version Latest

function Write-ShellForgeLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'ACTION')]
        [string]$Level,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Operation = 'General'
    )

    $logPath = Get-ShellForgePath -PathType 'LogFile' -Ensure
    $timestamp = [DateTimeOffset]::UtcNow.ToString('o')
    $entry = '[{0}] [{1}] [{2}] {3}{4}' -f $timestamp, $Level, $Operation, $Message, [Environment]::NewLine
    $utf8Encoding = [System.Text.UTF8Encoding]::new($false)
    $maxLogSizeBytes = 2MB
    $rotatedLogPath = [System.IO.Path]::ChangeExtension($logPath, '.1.log')

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            if ((Test-Path -LiteralPath $logPath) -and ((Get-Item -LiteralPath $logPath).PSIsContainer)) {
                return
            }

            if (Test-Path -LiteralPath $logPath) {
                $logItem = Get-Item -LiteralPath $logPath -ErrorAction Stop
                if (-not $logItem.PSIsContainer -and $logItem.Length -gt $maxLogSizeBytes) {
                    if (Test-Path -LiteralPath $rotatedLogPath) {
                        Remove-Item -LiteralPath $rotatedLogPath -Force -ErrorAction SilentlyContinue
                    }

                    Move-Item -LiteralPath $logPath -Destination $rotatedLogPath -Force
                }
            }

            [System.IO.File]::AppendAllText($logPath, $entry, $utf8Encoding)
            return
        }
        catch {
            if ($attempt -lt 3) {
                Start-Sleep -Milliseconds (50 * $attempt)
                continue
            }

            Write-Verbose ("ShellForge log write failed: {0}" -f $_.Exception.Message)
        }
    }
}
