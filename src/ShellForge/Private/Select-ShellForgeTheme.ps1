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

    $desiredThemeOrder = @(
        'CyberGlass',
        'Arctic Void',
        'Red Tactical',
        'Neon Grid',
        'Obsidian Nord',
        'Amber SOC',
        'Purple Forge',
        'Graphite Pulse',
        'Eclipse Matrix'
    )

    $themeIndex = @{}
    foreach ($availableTheme in @(Get-ShellForgeTheme)) {
        $themeIndex[[string]$availableTheme.Name] = $availableTheme
    }

    $orderedThemes = [System.Collections.Generic.List[object]]::new()
    foreach ($desiredThemeName in $desiredThemeOrder) {
        if ($themeIndex.Contains($desiredThemeName)) {
            [void]$orderedThemes.Add($themeIndex[$desiredThemeName])
        }
    }

    foreach ($remainingTheme in @(Get-ShellForgeTheme | Sort-Object -Property Name)) {
        if ($desiredThemeOrder -notcontains $remainingTheme.Name) {
            [void]$orderedThemes.Add($remainingTheme)
        }
    }

    $availableThemes = @($orderedThemes)
    if ($availableThemes.Count -eq 0) {
        throw 'No ShellForge theme is available. Add a theme JSON file to the themes folder first.'
    }

    Show-ShellForgeHeader -Title $Title -Subtitle $Subtitle
    $displayedCategories = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    for ($index = 0; $index -lt $availableThemes.Count; $index++) {
        $theme = $availableThemes[$index]
        $category = Get-ShellForgeThemeCategory -Theme $theme
        if (-not $displayedCategories.Contains($category)) {
            [void]$displayedCategories.Add($category)
            Write-ShellForgeSectionTitle -Title $category
        }

        $detailText = '{0} / {1} / {2}  |  {3}' -f $theme.promptLayout.type, $theme.promptLayout.lineMode, $theme.promptLayout.density, (Get-ShellForgeThemeDescriptor -Theme $theme)
        Write-ShellForgeMenuOption -Index ($index + 1) -Text $theme.Name -Detail $detailText
    }

    Write-ShellForgeSectionTitle -Title 'Custom'
    Write-ShellForgeMenuOption -Index 10 -Text 'Custom Builder' -Detail 'Create your own prompt, palette and segment profile'
    Write-ShellForgeMenuOption -Index 0 -Text 'Exit' -Detail 'Leave ShellForge without changing the session'
    Write-Host ''
    Write-Host ('Press Enter to select [1] {0}.' -f $availableThemes[0].Name) -ForegroundColor DarkGray
    $allowedValues = [System.Collections.Generic.List[int]]::new()
    [void]$allowedValues.Add(0)
    foreach ($value in 1..$availableThemes.Count) {
        [void]$allowedValues.Add([int]$value)
    }
    [void]$allowedValues.Add(10)

    $selection = Read-ShellForgeMenuSelection -Prompt 'Choose a theme' -AllowedValues $allowedValues.ToArray() -DefaultValue 1
    if ($selection -eq 0) {
        return $null
    }

    if ($selection -eq 10) {
        $customThemeResult = Invoke-ShellForgeCustomBuilderMenu
        if ($null -eq $customThemeResult) {
            return $null
        }

        if ($customThemeResult.PSObject.Properties.Name -contains 'SavedPath' -and -not [string]::IsNullOrWhiteSpace([string]$customThemeResult.SavedPath)) {
            return (Resolve-ShellForgeTheme -Path $customThemeResult.SavedPath)
        }

        return (Resolve-ShellForgeTheme -Theme $customThemeResult.Theme)
    }

    return (Resolve-ShellForgeTheme -Path $availableThemes[$selection - 1].SourcePath)
}
