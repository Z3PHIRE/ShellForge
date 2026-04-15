Set-StrictMode -Version Latest

function Get-ShellForgePlatformInfo {
    [CmdletBinding()]
    param()

    $platform = 'Windows'
    $runtimeInformationType = [System.Type]::GetType('System.Runtime.InteropServices.RuntimeInformation, System.Runtime.InteropServices.RuntimeInformation')
    if ($null -ne $runtimeInformationType) {
        if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
            $platform = 'Windows'
        }
        elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Linux)) {
            $platform = 'Linux'
        }
        elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) {
            $platform = 'MacOS'
        }
        else {
            $platform = 'Unknown'
        }
    }

    return [pscustomobject]@{
        Platform  = $platform
        PSEdition = [string]$PSVersionTable.PSEdition
        PSVersion = [string]$PSVersionTable.PSVersion
    }
}

