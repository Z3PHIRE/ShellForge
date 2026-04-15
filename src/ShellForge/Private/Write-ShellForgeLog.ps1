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

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            if ((Test-Path -LiteralPath $logPath) -and ((Get-Item -LiteralPath $logPath).PSIsContainer)) {
                return
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
