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
        Show-ShellForgeThemePreview -Theme $selectedTheme
        Write-ShellForgeMenuOption -Index 1 -Text 'Apply to the current session'
        Write-ShellForgeMenuOption -Index 2 -Text 'Install into the PowerShell profile'
        Write-ShellForgeMenuOption -Index 3 -Text 'Validate this theme'
        Write-ShellForgeMenuOption -Index 4 -Text 'Choose another theme'
        Write-ShellForgeMenuOption -Index 0 -Text 'Exit'

        $action = Read-ShellForgeMenuSelection -Prompt 'Choose an action' -AllowedValues @(0, 1, 2, 3, 4) -DefaultValue 1
        switch ($action) {
            0 {
                return
            }
            1 {
                Use-ShellForgeTheme -Path $selectedTheme.SourcePath | Out-Null
                Write-Host ''
                Write-Host ('Theme applied: {0}' -f $selectedTheme.Name) -ForegroundColor Green
                Read-Host -Prompt 'Press Enter to continue' | Out-Null
            }
            2 {
                Install-ShellForgeTheme -Path $selectedTheme.SourcePath | Out-Null
                Write-Host ''
                Write-Host ('Theme installed: {0}' -f $selectedTheme.Name) -ForegroundColor Green
                Read-Host -Prompt 'Press Enter to continue' | Out-Null
            }
            3 {
                $validationResult = Test-ShellForgeTheme -Path $selectedTheme.SourcePath
                Write-Host ''
                if ($validationResult.IsValid) {
                    Write-Host ('Theme is valid: {0}' -f $selectedTheme.Name) -ForegroundColor Green
                }
                else {
                    Write-Host ('Theme is invalid: {0}' -f $selectedTheme.Name) -ForegroundColor Red
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

