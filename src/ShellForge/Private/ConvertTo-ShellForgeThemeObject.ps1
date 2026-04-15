Set-StrictMode -Version Latest

function ConvertTo-ShellForgeThemeObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [object]$InputObject
    )

    process {
        if ($InputObject -is [string] -and (Test-Path -LiteralPath $InputObject)) {
            $themeSource = Read-ShellForgeJsonFile -Path $InputObject
        }
        else {
            $themeSource = $InputObject
        }

        if ($null -eq $themeSource) {
            throw 'Theme input cannot be null.'
        }

        return [pscustomobject]@{
            schemaVersion = [string]$themeSource.schemaVersion
            name          = [string]$themeSource.name
            slug          = [string]$themeSource.slug
            description   = [string]$themeSource.description
            intent        = [string]$themeSource.intent
            promptLayout  = [pscustomobject]@{
                type              = [string]$themeSource.promptLayout.type
                density           = [string]$themeSource.promptLayout.density
                lineMode          = [string]$themeSource.promptLayout.lineMode
                separatorStyle    = [string]$themeSource.promptLayout.separatorStyle
                promptSymbol      = [string]$themeSource.promptLayout.promptSymbol
                adminWarningStyle = [string]$themeSource.promptLayout.adminWarningStyle
            }
            palette       = [pscustomobject]@{
                background      = [string]$themeSource.palette.background
                surface         = [string]$themeSource.palette.surface
                accent          = [string]$themeSource.palette.accent
                accentSecondary = [string]$themeSource.palette.accentSecondary
                text            = [string]$themeSource.palette.text
                muted           = [string]$themeSource.palette.muted
                success         = [string]$themeSource.palette.success
                warning         = [string]$themeSource.palette.warning
                error           = [string]$themeSource.palette.error
                info            = [string]$themeSource.palette.info
            }
            segments      = [pscustomobject]@{
                gitEnabled           = ConvertTo-ShellForgeBoolean -Value $themeSource.segments.gitEnabled -FieldName 'segments.gitEnabled'
                adminEnabled         = ConvertTo-ShellForgeBoolean -Value $themeSource.segments.adminEnabled -FieldName 'segments.adminEnabled'
                statusEnabled        = ConvertTo-ShellForgeBoolean -Value $themeSource.segments.statusEnabled -FieldName 'segments.statusEnabled'
                runtimeEnabled       = ConvertTo-ShellForgeBoolean -Value $themeSource.segments.runtimeEnabled -FieldName 'segments.runtimeEnabled'
                executionTimeEnabled = ConvertTo-ShellForgeBoolean -Value $themeSource.segments.executionTimeEnabled -FieldName 'segments.executionTimeEnabled'
                batteryEnabled       = ConvertTo-ShellForgeBoolean -Value $themeSource.segments.batteryEnabled -FieldName 'segments.batteryEnabled'
                timeEnabled          = ConvertTo-ShellForgeBoolean -Value $themeSource.segments.timeEnabled -FieldName 'segments.timeEnabled'
                hostEnabled          = ConvertTo-ShellForgeBoolean -Value $themeSource.segments.hostEnabled -FieldName 'segments.hostEnabled'
                userEnabled          = ConvertTo-ShellForgeBoolean -Value $themeSource.segments.userEnabled -FieldName 'segments.userEnabled'
                pathMode             = [string]$themeSource.segments.pathMode
            }
            iconDensity   = [string]$themeSource.iconDensity
            psReadLine    = [pscustomobject]@{
                editMode             = [string]$themeSource.psReadLine.editMode
                predictionColor      = [string]$themeSource.psReadLine.predictionColor
                continuationPrompt   = [string]$themeSource.psReadLine.continuationPrompt
                colors               = [pscustomobject]@{
                    Command          = [string]$themeSource.psReadLine.colors.Command
                    Comment          = [string]$themeSource.psReadLine.colors.Comment
                    Keyword          = [string]$themeSource.psReadLine.colors.Keyword
                    String           = [string]$themeSource.psReadLine.colors.String
                    Number           = [string]$themeSource.psReadLine.colors.Number
                    Operator         = [string]$themeSource.psReadLine.colors.Operator
                    Variable         = [string]$themeSource.psReadLine.colors.Variable
                    Member           = [string]$themeSource.psReadLine.colors.Member
                    Parameter        = [string]$themeSource.psReadLine.colors.Parameter
                    Type             = [string]$themeSource.psReadLine.colors.Type
                    Selection        = [string]$themeSource.psReadLine.colors.Selection
                    InlinePrediction = [string]$themeSource.psReadLine.colors.InlinePrediction
                    Error            = [string]$themeSource.psReadLine.colors.Error
                }
            }
            terminal      = [pscustomobject]@{
                backgroundHex     = [string]$themeSource.terminal.backgroundHex
                opacityPercent    = [int]$themeSource.terminal.opacityPercent
                cursorStyle       = [string]$themeSource.terminal.cursorStyle
                fontRecommendation = [string]$themeSource.terminal.fontRecommendation
            }
            compatibility = [pscustomobject]@{
                nativePromptSupported   = ConvertTo-ShellForgeBoolean -Value $themeSource.compatibility.nativePromptSupported -FieldName 'compatibility.nativePromptSupported'
                ohMyPoshProfileAvailable = ConvertTo-ShellForgeBoolean -Value $themeSource.compatibility.ohMyPoshProfileAvailable -FieldName 'compatibility.ohMyPoshProfileAvailable'
                minimumPowerShell       = [string]$themeSource.compatibility.minimumPowerShell
                notes                   = @($themeSource.compatibility.notes)
            }
            preview       = [pscustomobject]@{
                sampleCommand = [string]$themeSource.preview.sampleCommand
                promptExample = [string]$themeSource.preview.promptExample
            }
        }
    }
}

