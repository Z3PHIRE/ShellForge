Set-StrictMode -Version Latest

function Invoke-ShellForge {
    <#
    .SYNOPSIS
    Opens the interactive ShellForge menu.
    #>
    [CmdletBinding()]
    param()

    while ($true) {
        $selectedTheme = Select-ShellForgeTheme -Title 'SHELLFORGE' -Subtitle 'Interactive theme menu'
        if ($null -eq $selectedTheme) {
            return
        }

        Show-ShellForgeHeader -Title 'SHELLFORGE' -Subtitle 'Theme preview'
        Show-ShellForgeThemePreview -Theme $selectedTheme.Theme
        Write-ShellForgeSectionTitle -Title 'Actions'
        Write-ShellForgeMenuOption -Index 1 -Text 'Apply to the current session' -Detail 'Load the theme now without editing the profile'
        Write-ShellForgeMenuOption -Index 2 -Text 'Install into the PowerShell profile' -Detail 'Backup, persist and auto-load this theme'
        Write-ShellForgeMenuOption -Index 3 -Text 'Validate this theme' -Detail 'Check schema, compatibility and built-in rules'
        Write-ShellForgeMenuOption -Index 4 -Text 'Choose another theme' -Detail 'Return to the preset and builder selection menu'
        Write-ShellForgeMenuOption -Index 0 -Text 'Exit' -Detail 'Leave the interactive menu'

        $action = Read-ShellForgeMenuSelection -Prompt 'Choose an action' -AllowedValues @(0, 1, 2, 3, 4) -DefaultValue 1
        switch ($action) {
            0 {
                return
            }
            1 {
                Use-ShellForgeTheme -Theme $selectedTheme.Theme | Out-Null
                Write-Host ''
                Write-Host ('Theme applied: {0}' -f $selectedTheme.Theme.Name) -ForegroundColor Green
                Read-Host -Prompt 'Press Enter to continue' | Out-Null
            }
            2 {
                Install-ShellForgeTheme -Theme $selectedTheme.Theme | Out-Null
                Write-Host ''
                Write-Host ('Theme installed: {0}' -f $selectedTheme.Theme.Name) -ForegroundColor Green
                Read-Host -Prompt 'Press Enter to continue' | Out-Null
            }
            3 {
                $validationResult = Test-ShellForgeTheme -Theme $selectedTheme.Theme
                Write-Host ''
                if ($validationResult.IsValid) {
                    Write-Host ('Theme is valid: {0}' -f $selectedTheme.Theme.Name) -ForegroundColor Green
                }
                else {
                    Write-Host ('Theme is invalid: {0}' -f $selectedTheme.Theme.Name) -ForegroundColor Red
                    foreach ($validationError in @($validationResult.Errors)) {
                        Write-Host (' - {0}' -f $validationError) -ForegroundColor Yellow
                    }
                }

                Read-Host -Prompt 'Press Enter to continue' | Out-Null
            }
            4 {
                continue
            }
        }
    }
}
