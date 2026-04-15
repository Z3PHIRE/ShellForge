Set-StrictMode -Version Latest

function ConvertTo-ShellForgeBoolean {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FieldName
    )

    if ($Value -is [bool]) {
        return $Value
    }

    if ($Value -is [string]) {
        switch ($Value.Trim().ToLowerInvariant()) {
            'true' { return $true }
            'false' { return $false }
            '1' { return $true }
            '0' { return $false }
            'yes' { return $true }
            'no' { return $false }
        }
    }

    if ($Value -is [int]) {
        switch ($Value) {
            1 { return $true }
            0 { return $false }
        }
    }

    throw (New-ShellForgeConfigError -FieldName $FieldName -Message ("Expected a boolean value but received '{0}'." -f $Value))
}

