Set-StrictMode -Version Latest

function Get-ShellForgeBundledResourcePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Themes', 'Previews')]
        [string]$ResourceType
    )

    $moduleContentPath = Join-Path -Path $script:ShellForgeModuleRoot -ChildPath 'Content'
    $repoRoot = [System.IO.Path]::GetFullPath((Join-Path -Path $script:ShellForgeModuleRoot -ChildPath '..\..\'))

    switch ($ResourceType) {
        'Themes' {
            $candidatePaths = @(
                (Join-Path -Path $moduleContentPath -ChildPath 'Themes')
                (Join-Path -Path $repoRoot -ChildPath 'themes')
            )
        }
        'Previews' {
            $candidatePaths = @(
                (Join-Path -Path $moduleContentPath -ChildPath 'Previews')
                (Join-Path -Path $repoRoot -ChildPath 'assets\previews')
            )
        }
        default {
            throw "Unsupported resource type '$ResourceType'."
        }
    }

    foreach ($candidatePath in $candidatePaths) {
        if (Test-Path -LiteralPath $candidatePath) {
            return [System.IO.Path]::GetFullPath($candidatePath)
        }
    }

    throw "ShellForge resource path for '$ResourceType' could not be located."
}
