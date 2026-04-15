Set-StrictMode -Version Latest

$privateFunctionFiles = Get-ChildItem -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath 'Private') -Filter '*.ps1' -File | Sort-Object -Property Name
foreach ($privateFunctionFile in $privateFunctionFiles) {
    . $privateFunctionFile.FullName
}

$publicFunctionFiles = Get-ChildItem -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath 'Public') -Filter '*.ps1' -File | Sort-Object -Property Name
foreach ($publicFunctionFile in $publicFunctionFiles) {
    . $publicFunctionFile.FullName
}

$script:ShellForgeModuleRoot = $PSScriptRoot
$script:ShellForgeModuleManifestPath = Join-Path -Path $PSScriptRoot -ChildPath 'ShellForge.psd1'
$script:ShellForgeProfileMarkerStart = '# >>> ShellForge Managed Block >>>'
$script:ShellForgeProfileMarkerEnd = '# <<< ShellForge Managed Block <<<'
$script:ShellForgeCurrentTheme = $null
$script:ShellForgePromptInstalled = $false

Set-Alias -Name shellforge -Value Invoke-ShellForge -Scope Global

Export-ModuleMember -Function @(
    'Backup-ShellForgeConfig',
    'Get-ShellForgeTheme',
    'Import-ShellForgeProfile',
    'Install-ShellForgeTheme',
    'Invoke-ShellForge',
    'New-ShellForgeTheme',
    'Restore-ShellForgeConfig',
    'Test-ShellForgeTheme',
    'Use-ShellForgeTheme'
) -Alias @('shellforge')
