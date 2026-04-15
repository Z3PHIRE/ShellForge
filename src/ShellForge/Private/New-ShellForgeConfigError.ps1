Set-StrictMode -Version Latest

function New-ShellForgeConfigError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FieldName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message
    )

    return [System.ArgumentException]::new(("Configuration error for '{0}': {1}" -f $FieldName, $Message), $FieldName)
}

