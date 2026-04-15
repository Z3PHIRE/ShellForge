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
    $entry = '[{0}] [{1}] [{2}] {3}' -f $timestamp, $Level, $Operation, $Message
    Add-Content -LiteralPath $logPath -Value $entry -Encoding utf8
}

