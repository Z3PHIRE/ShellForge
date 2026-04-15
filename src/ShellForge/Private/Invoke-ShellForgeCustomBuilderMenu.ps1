Set-StrictMode -Version Latest

function Invoke-ShellForgeCustomBuilderMenu {
    [CmdletBinding()]
    param()

    Show-ShellForgeHeader -Title 'SHELLFORGE BUILDER' -Subtitle 'Custom theme builder'
    $themeName = Read-Host -Prompt 'Theme name'
    if ([string]::IsNullOrWhiteSpace($themeName)) {
        $themeName = 'Custom Forge'
    }

    $description = Read-Host -Prompt 'Short description'
    if ([string]::IsNullOrWhiteSpace($description)) {
        $description = 'Custom ShellForge theme'
    }

    Write-Host ''
    Write-Host 'Prompt style' -ForegroundColor Cyan
    Write-ShellForgeMenuOption -Index 1 -Text 'Glass'
    Write-ShellForgeMenuOption -Index 2 -Text 'Minimal'
    Write-ShellForgeMenuOption -Index 3 -Text 'Tactical'
    Write-ShellForgeMenuOption -Index 4 -Text 'Grid'
    Write-ShellForgeMenuOption -Index 5 -Text 'Nordic'
    Write-ShellForgeMenuOption -Index 6 -Text 'SOC'
    Write-ShellForgeMenuOption -Index 7 -Text 'Boxed'
    Write-ShellForgeMenuOption -Index 8 -Text 'PathHeavy'
    Write-ShellForgeMenuOption -Index 9 -Text 'Matrix'
    $promptStyleMap = @{
        1 = 'Glass'
        2 = 'Minimal'
        3 = 'Tactical'
        4 = 'Grid'
        5 = 'Nordic'
        6 = 'SOC'
        7 = 'Boxed'
        8 = 'PathHeavy'
        9 = 'Matrix'
    }
    $promptStyle = $promptStyleMap[(Read-ShellForgeMenuSelection -Prompt 'Select prompt style' -AllowedValues @(1..9) -DefaultValue 1)]

    Write-Host ''
    Write-Host 'Palette family' -ForegroundColor Cyan
    Write-ShellForgeMenuOption -Index 1 -Text 'Cyber'
    Write-ShellForgeMenuOption -Index 2 -Text 'Frost'
    Write-ShellForgeMenuOption -Index 3 -Text 'Tactical'
    Write-ShellForgeMenuOption -Index 4 -Text 'Neon'
    Write-ShellForgeMenuOption -Index 5 -Text 'Nord'
    Write-ShellForgeMenuOption -Index 6 -Text 'Amber'
    Write-ShellForgeMenuOption -Index 7 -Text 'Purple'
    Write-ShellForgeMenuOption -Index 8 -Text 'Graphite'
    Write-ShellForgeMenuOption -Index 9 -Text 'Matrix'
    $paletteMap = @{
        1 = 'Cyber'
        2 = 'Frost'
        3 = 'Tactical'
        4 = 'Neon'
        5 = 'Nord'
        6 = 'Amber'
        7 = 'Purple'
        8 = 'Graphite'
        9 = 'Matrix'
    }
    $paletteName = $paletteMap[(Read-ShellForgeMenuSelection -Prompt 'Select palette' -AllowedValues @(1..9) -DefaultValue 1)]

    Write-Host ''
    Write-Host 'Density' -ForegroundColor Cyan
    Write-ShellForgeMenuOption -Index 1 -Text 'Low'
    Write-ShellForgeMenuOption -Index 2 -Text 'Medium'
    Write-ShellForgeMenuOption -Index 3 -Text 'High'
    $densityMap = @{ 1 = 'Low'; 2 = 'Medium'; 3 = 'High' }
    $density = $densityMap[(Read-ShellForgeMenuSelection -Prompt 'Select density' -AllowedValues @(1, 2, 3) -DefaultValue 2)]

    Write-Host ''
    Write-Host 'Line mode' -ForegroundColor Cyan
    Write-ShellForgeMenuOption -Index 1 -Text 'SingleLine'
    Write-ShellForgeMenuOption -Index 2 -Text 'DoubleLine'
    $lineModeMap = @{ 1 = 'SingleLine'; 2 = 'DoubleLine' }
    $lineMode = $lineModeMap[(Read-ShellForgeMenuSelection -Prompt 'Select line mode' -AllowedValues @(1, 2) -DefaultValue 1)]

    Write-Host ''
    Write-Host 'Icon density' -ForegroundColor Cyan
    Write-ShellForgeMenuOption -Index 1 -Text 'None'
    Write-ShellForgeMenuOption -Index 2 -Text 'Low'
    Write-ShellForgeMenuOption -Index 3 -Text 'Medium'
    Write-ShellForgeMenuOption -Index 4 -Text 'High'
    $iconDensityMap = @{ 1 = 'None'; 2 = 'Low'; 3 = 'Medium'; 4 = 'High' }
    $iconDensity = $iconDensityMap[(Read-ShellForgeMenuSelection -Prompt 'Select icon density' -AllowedValues @(1, 2, 3, 4) -DefaultValue 3)]

    Write-Host ''
    Write-Host 'Path mode' -ForegroundColor Cyan
    Write-ShellForgeMenuOption -Index 1 -Text 'Leaf'
    Write-ShellForgeMenuOption -Index 2 -Text 'Short'
    Write-ShellForgeMenuOption -Index 3 -Text 'Full'
    $pathModeMap = @{ 1 = 'Leaf'; 2 = 'Short'; 3 = 'Full' }
    $pathMode = $pathModeMap[(Read-ShellForgeMenuSelection -Prompt 'Select path mode' -AllowedValues @(1, 2, 3) -DefaultValue 2)]

    Write-Host ''
    Write-Host 'Admin warning style' -ForegroundColor Cyan
    Write-ShellForgeMenuOption -Index 1 -Text 'Subtle'
    Write-ShellForgeMenuOption -Index 2 -Text 'Inline'
    Write-ShellForgeMenuOption -Index 3 -Text 'Banner'
    $adminStyleMap = @{ 1 = 'Subtle'; 2 = 'Inline'; 3 = 'Banner' }
    $adminWarningStyle = $adminStyleMap[(Read-ShellForgeMenuSelection -Prompt 'Select admin warning style' -AllowedValues @(1, 2, 3) -DefaultValue 2)]

    Write-Host ''
    Write-Host 'Terminal background recommendation' -ForegroundColor Cyan
    Write-ShellForgeMenuOption -Index 1 -Text 'Use palette background'
    Write-ShellForgeMenuOption -Index 2 -Text 'Pure black'
    Write-ShellForgeMenuOption -Index 3 -Text 'Graphite dark'
    Write-ShellForgeMenuOption -Index 4 -Text 'Navy dark'
    $backgroundMap = @{
        1 = ''
        2 = '#000000'
        3 = '#12161A'
        4 = '#07101A'
    }
    $backgroundOverride = $backgroundMap[(Read-ShellForgeMenuSelection -Prompt 'Select terminal background' -AllowedValues @(1, 2, 3, 4) -DefaultValue 1)]

    Write-Host ''
    Write-Host 'Opacity recommendation' -ForegroundColor Cyan
    Write-ShellForgeMenuOption -Index 1 -Text '65%'
    Write-ShellForgeMenuOption -Index 2 -Text '80%'
    Write-ShellForgeMenuOption -Index 3 -Text '90%'
    Write-ShellForgeMenuOption -Index 4 -Text '100%'
    $opacityMap = @{ 1 = 65; 2 = 80; 3 = 90; 4 = 100 }
    $opacityPercent = $opacityMap[(Read-ShellForgeMenuSelection -Prompt 'Select opacity' -AllowedValues @(1, 2, 3, 4) -DefaultValue 3)]

    Write-Host ''
    Write-Host 'Cursor style' -ForegroundColor Cyan
    Write-ShellForgeMenuOption -Index 1 -Text 'Block'
    Write-ShellForgeMenuOption -Index 2 -Text 'Line'
    Write-ShellForgeMenuOption -Index 3 -Text 'Underline'
    $cursorMap = @{ 1 = 'Block'; 2 = 'Line'; 3 = 'Underline' }
    $cursorStyle = $cursorMap[(Read-ShellForgeMenuSelection -Prompt 'Select cursor style' -AllowedValues @(1, 2, 3) -DefaultValue 2)]

    Write-Host ''
    Write-Host 'PSReadLine syntax profile' -ForegroundColor Cyan
    Write-ShellForgeMenuOption -Index 1 -Text 'Palette balanced'
    Write-ShellForgeMenuOption -Index 2 -Text 'High contrast'
    Write-ShellForgeMenuOption -Index 3 -Text 'Calm'
    Write-ShellForgeMenuOption -Index 4 -Text 'Neon'
    $syntaxMap = @{ 1 = 'Palette'; 2 = 'HighContrast'; 3 = 'Calm'; 4 = 'Neon' }
    $syntaxProfile = $syntaxMap[(Read-ShellForgeMenuSelection -Prompt 'Select PSReadLine profile' -AllowedValues @(1, 2, 3, 4) -DefaultValue 1)]

    Write-Host ''
    Write-Host 'Inline prediction color' -ForegroundColor Cyan
    Write-ShellForgeMenuOption -Index 1 -Text 'Muted'
    Write-ShellForgeMenuOption -Index 2 -Text 'Accent'
    Write-ShellForgeMenuOption -Index 3 -Text 'Secondary accent'
    Write-ShellForgeMenuOption -Index 4 -Text 'Soft silver'
    $predictionColorMap = @{
        1 = ''
        2 = '#6FE7FF'
        3 = '#C89BFF'
        4 = '#B7C0CB'
    }
    $predictionColor = $predictionColorMap[(Read-ShellForgeMenuSelection -Prompt 'Select prediction color' -AllowedValues @(1, 2, 3, 4) -DefaultValue 1)]

    Write-Host ''
    Write-Host 'Success color' -ForegroundColor Cyan
    Write-ShellForgeMenuOption -Index 1 -Text 'Palette success'
    Write-ShellForgeMenuOption -Index 2 -Text 'Mint green'
    Write-ShellForgeMenuOption -Index 3 -Text 'Bright cyan'
    Write-ShellForgeMenuOption -Index 4 -Text 'Amber gold'
    $successColorMap = @{
        1 = ''
        2 = '#63F0B2'
        3 = '#6FE7FF'
        4 = '#FFD166'
    }
    $successColor = $successColorMap[(Read-ShellForgeMenuSelection -Prompt 'Select success color' -AllowedValues @(1, 2, 3, 4) -DefaultValue 1)]

    Write-Host ''
    Write-Host 'Error color' -ForegroundColor Cyan
    Write-ShellForgeMenuOption -Index 1 -Text 'Palette error'
    Write-ShellForgeMenuOption -Index 2 -Text 'Hot red'
    Write-ShellForgeMenuOption -Index 3 -Text 'Rose magenta'
    Write-ShellForgeMenuOption -Index 4 -Text 'Orange alert'
    $errorColorMap = @{
        1 = ''
        2 = '#FF5C5C'
        3 = '#FF5FA2'
        4 = '#FF8A3D'
    }
    $errorColor = $errorColorMap[(Read-ShellForgeMenuSelection -Prompt 'Select error color' -AllowedValues @(1, 2, 3, 4) -DefaultValue 1)]

    Write-Host ''
    Write-Host 'Segments' -ForegroundColor Cyan
    $gitEnabled = Read-ShellForgeBooleanChoice -Prompt 'Git segment'
    $adminEnabled = Read-ShellForgeBooleanChoice -Prompt 'Admin warning segment'
    $statusEnabled = Read-ShellForgeBooleanChoice -Prompt 'Status segment'
    $runtimeEnabled = Read-ShellForgeBooleanChoice -Prompt 'Runtime segment'
    $executionTimeEnabled = Read-ShellForgeBooleanChoice -Prompt 'Execution time segment'
    $batteryEnabled = Read-ShellForgeBooleanChoice -Prompt 'Battery segment' -DefaultValue $false
    $timeEnabled = Read-ShellForgeBooleanChoice -Prompt 'Clock segment'
    $hostEnabled = Read-ShellForgeBooleanChoice -Prompt 'Host segment' -DefaultValue $false
    $userEnabled = Read-ShellForgeBooleanChoice -Prompt 'User segment' -DefaultValue $false

    $theme = New-ShellForgeThemeTemplate -Name $themeName `
        -Description $description `
        -PaletteName $paletteName `
        -PromptStyle $promptStyle `
        -Density $density `
        -LineMode $lineMode `
        -IconDensity $iconDensity `
        -PathMode $pathMode `
        -AdminWarningStyle $adminWarningStyle `
        -SyntaxProfile $syntaxProfile `
        -CursorStyle $cursorStyle `
        -OpacityPercent $opacityPercent `
        -GitEnabled $gitEnabled `
        -AdminEnabled $adminEnabled `
        -StatusEnabled $statusEnabled `
        -RuntimeEnabled $runtimeEnabled `
        -ExecutionTimeEnabled $executionTimeEnabled `
        -BatteryEnabled $batteryEnabled `
        -TimeEnabled $timeEnabled `
        -HostEnabled $hostEnabled `
        -UserEnabled $userEnabled `
        -BackgroundHex $backgroundOverride `
        -PredictionColor $predictionColor `
        -SuccessColor $successColor `
        -ErrorColor $errorColor

    $saveTheme = Read-ShellForgeBooleanChoice -Prompt 'Save this theme to your local ShellForge library'
    $savedPath = ''
    if ($saveTheme) {
        $savedPath = Join-Path -Path (Get-ShellForgePath -PathType 'Themes' -Ensure) -ChildPath ('{0}.json' -f $theme.slug)
        Write-ShellForgeJsonFile -Path $savedPath -Data $theme -Depth 20
    }

    return [pscustomobject]@{
        Theme     = $theme
        SavedPath = $savedPath
    }
}
