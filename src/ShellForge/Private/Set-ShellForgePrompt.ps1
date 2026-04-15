Set-StrictMode -Version Latest

function Set-ShellForgePrompt {
    [CmdletBinding()]
    param()

    $promptScript = {
        [CmdletBinding()]
        param()

        Get-ShellForgePromptText
    }

    Set-Item -Path Function:\global:prompt -Value $promptScript
    $script:ShellForgePromptInstalled = $true
}

