@{
    RootModule        = 'ShellForge.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '8a61517e-823a-4b60-b5b3-4f5ad4f61753'
    Author            = 'ShellForge Contributors'
    CompanyName       = 'Open Source'
    Copyright         = '(c) 2026 ShellForge contributors. MIT License.'
    Description       = 'Cross-platform PowerShell theme studio and deployment engine with native prompt rendering, backup and safe deployment workflows.'
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FunctionsToExport = @(
        'Backup-ShellForgeConfig',
        'Get-ShellForgeTheme',
        'Import-ShellForgeProfile',
        'Install-ShellForgeTheme',
        'Invoke-ShellForge',
        'New-ShellForgeTheme',
        'Restore-ShellForgeConfig',
        'Test-ShellForgeTheme',
        'Use-ShellForgeTheme'
    )
    AliasesToExport   = @('shellforge')
    PrivateData       = @{
        PSData = @{
            Tags         = @('powershell', 'theme', 'prompt', 'terminal', 'deployment', 'psreadline', 'shellforge')
            ProjectUri   = 'https://github.com/Z3PHIRE/ShellForge'
            LicenseUri   = 'https://github.com/Z3PHIRE/ShellForge/blob/main/LICENSE'
            ReleaseNotes = 'Initial production release with built-in presets, custom builder, interactive menu and safe profile integration.'
        }
    }
}
