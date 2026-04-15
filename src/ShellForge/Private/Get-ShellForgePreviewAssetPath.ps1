Set-StrictMode -Version Latest

function Get-ShellForgePreviewAssetPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ThemeSlug
    )

    $previewPath = Get-ShellForgeBundledResourcePath -ResourceType 'Previews'
    $candidatePath = Join-Path -Path $previewPath -ChildPath ('{0}.svg' -f $ThemeSlug)
    if (Test-Path -LiteralPath $candidatePath) {
        return [System.IO.Path]::GetFullPath($candidatePath)
    }

    return ''
}
