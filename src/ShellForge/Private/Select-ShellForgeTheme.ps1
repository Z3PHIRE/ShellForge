Set-StrictMode -Version Latest

function Select-ShellForgeTheme {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Title = 'SHELLFORGE',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Subtitle = 'Select a theme'
    )

    $availableThemes = @(Get-ShellForgeTheme | Sort-Object -Property Name)
    if ($availableThemes.Count -eq 0) {
        throw 'No ShellForge theme is available. Add a theme JSON file to the themes folder first.'
    }

    Show-ShellForgeHeader -Title $Title -Subtitle $Subtitle
    for ($index = 0; $index -lt $availableThemes.Count; $index++) {
        $theme = $availableThemes[$index]
        Write-ShellForgeMenuOption -Index ($index + 1) -Text $theme.Name
    }

    Write-ShellForgeMenuOption -Index 0 -Text 'Exit'
    Write-Host ''
    Write-Host 'Press Enter to select the first theme.' -ForegroundColor DarkGray
    $selection = Read-ShellForgeMenuSelection -Prompt 'Choose a theme' -AllowedValues @(0..$availableThemes.Count) -DefaultValue 1
    if ($selection -eq 0) {
        return $null
    }

    return $availableThemes[$selection - 1]
}
