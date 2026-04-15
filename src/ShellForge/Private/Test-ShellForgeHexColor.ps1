Set-StrictMode -Version Latest

function Test-ShellForgeHexColor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value
    )

    return ($Value -match '^#[0-9A-Fa-f]{6}$')
}

