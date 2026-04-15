Set-StrictMode -Version Latest

function ConvertTo-ShellForgeMenuSelection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$InputText,

        [Parameter(Mandatory)]
        [int[]]$AllowedValues
    )

    if ([string]::IsNullOrWhiteSpace($InputText)) {
        throw 'Menu selection cannot be empty.'
    }

    $parsedValue = 0
    if (-not [int]::TryParse($InputText.Trim(), [ref]$parsedValue)) {
        throw "Menu selection '$InputText' is not numeric."
    }

    if ($AllowedValues -notcontains $parsedValue) {
        throw "Menu selection '$parsedValue' is not in the allowed list."
    }

    return $parsedValue
}

function Read-ShellForgeMenuSelection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Prompt,

        [Parameter(Mandatory)]
        [int[]]$AllowedValues,

        [Parameter()]
        [AllowNull()]
        [int]$DefaultValue
    )

    $hasDefaultValue = $PSBoundParameters.ContainsKey('DefaultValue') -and $null -ne $DefaultValue
    while ($true) {
        $rawInput = Read-Host -Prompt $Prompt
        if ([string]::IsNullOrWhiteSpace($rawInput) -and $hasDefaultValue) {
            return [int]$DefaultValue
        }

        try {
            return (ConvertTo-ShellForgeMenuSelection -InputText $rawInput -AllowedValues $AllowedValues)
        }
        catch {
            Write-Host $_.Exception.Message -ForegroundColor Yellow
        }
    }
}

function Read-ShellForgeBooleanChoice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,

        [Parameter()]
        [bool]$DefaultValue = $true
    )

    Write-ShellForgeMenuOption -Index 1 -Text 'Enabled'
    Write-ShellForgeMenuOption -Index 2 -Text 'Disabled'
    $defaultMenuValue = if ($DefaultValue) { 1 } else { 2 }
    $selection = Read-ShellForgeMenuSelection -Prompt $Prompt -AllowedValues @(1, 2) -DefaultValue $defaultMenuValue
    return ($selection -eq 1)
}
