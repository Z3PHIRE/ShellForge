Set-StrictMode -Version Latest

function Assert-ShellForgeThemeObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [pscustomobject]$Theme
    )

    process {
        $errors = [System.Collections.Generic.List[string]]::new()
        $requiredStringFields = @(
            'schemaVersion',
            'name',
            'slug',
            'description',
            'intent',
            'promptLayout.type',
            'promptLayout.density',
            'promptLayout.lineMode',
            'promptLayout.separatorStyle',
            'promptLayout.promptSymbol',
            'promptLayout.adminWarningStyle',
            'segments.pathMode',
            'iconDensity',
            'psReadLine.editMode',
            'psReadLine.predictionColor',
            'psReadLine.continuationPrompt',
            'terminal.backgroundHex',
            'terminal.cursorStyle',
            'terminal.fontRecommendation',
            'compatibility.minimumPowerShell',
            'preview.sampleCommand',
            'preview.promptExample'
        )

        foreach ($fieldPath in $requiredStringFields) {
            $segments = $fieldPath -split '\.'
            $currentValue = $Theme
            foreach ($segmentName in $segments) {
                $currentValue = $currentValue.$segmentName
            }

            if ([string]::IsNullOrWhiteSpace([string]$currentValue)) {
                [void]$errors.Add("Missing required value: $fieldPath")
            }
        }

        if ($Theme.slug -notmatch '^[a-z0-9-]+$') {
            [void]$errors.Add("Theme slug '$($Theme.slug)' must use lowercase letters, numbers and dashes only.")
        }

        $allowedLayoutTypes = @('Glass', 'Minimal', 'Tactical', 'Grid', 'Nordic', 'SOC', 'Boxed', 'PathHeavy', 'Matrix', 'Custom')
        if ($allowedLayoutTypes -notcontains $Theme.promptLayout.type) {
            [void]$errors.Add("Unsupported prompt layout type '$($Theme.promptLayout.type)'.")
        }

        if (@('Low', 'Medium', 'High') -notcontains $Theme.promptLayout.density) {
            [void]$errors.Add("Unsupported prompt density '$($Theme.promptLayout.density)'.")
        }

        if (@('SingleLine', 'DoubleLine') -notcontains $Theme.promptLayout.lineMode) {
            [void]$errors.Add("Unsupported line mode '$($Theme.promptLayout.lineMode)'.")
        }

        if (@('Subtle', 'Inline', 'Banner') -notcontains $Theme.promptLayout.adminWarningStyle) {
            [void]$errors.Add("Unsupported admin warning style '$($Theme.promptLayout.adminWarningStyle)'.")
        }

        if (@('Leaf', 'Short', 'Full') -notcontains $Theme.segments.pathMode) {
            [void]$errors.Add("Unsupported path mode '$($Theme.segments.pathMode)'.")
        }

        if (@('None', 'Low', 'Medium', 'High') -notcontains $Theme.iconDensity) {
            [void]$errors.Add("Unsupported icon density '$($Theme.iconDensity)'.")
        }

        if (@('Windows', 'Emacs', 'Vi') -notcontains $Theme.psReadLine.editMode) {
            [void]$errors.Add("Unsupported PSReadLine edit mode '$($Theme.psReadLine.editMode)'.")
        }

        if (@('Block', 'Line', 'Underline') -notcontains $Theme.terminal.cursorStyle) {
            [void]$errors.Add("Unsupported cursor style '$($Theme.terminal.cursorStyle)'.")
        }

        if ([Version]$Theme.compatibility.minimumPowerShell -lt [Version]'5.1') {
            [void]$errors.Add("Minimum PowerShell version '$($Theme.compatibility.minimumPowerShell)' is below the supported floor.")
        }

        if ($Theme.terminal.opacityPercent -lt 10 -or $Theme.terminal.opacityPercent -gt 100) {
            [void]$errors.Add("Terminal opacity '$($Theme.terminal.opacityPercent)' must be between 10 and 100.")
        }

        $colorFields = @(
            $Theme.palette.background,
            $Theme.palette.surface,
            $Theme.palette.accent,
            $Theme.palette.accentSecondary,
            $Theme.palette.text,
            $Theme.palette.muted,
            $Theme.palette.success,
            $Theme.palette.warning,
            $Theme.palette.error,
            $Theme.palette.info,
            $Theme.psReadLine.predictionColor,
            $Theme.psReadLine.continuationPrompt,
            $Theme.psReadLine.colors.Command,
            $Theme.psReadLine.colors.Comment,
            $Theme.psReadLine.colors.Keyword,
            $Theme.psReadLine.colors.String,
            $Theme.psReadLine.colors.Number,
            $Theme.psReadLine.colors.Operator,
            $Theme.psReadLine.colors.Variable,
            $Theme.psReadLine.colors.Member,
            $Theme.psReadLine.colors.Parameter,
            $Theme.psReadLine.colors.Type,
            $Theme.psReadLine.colors.Selection,
            $Theme.psReadLine.colors.InlinePrediction,
            $Theme.psReadLine.colors.Error,
            $Theme.terminal.backgroundHex
        )

        foreach ($colorValue in $colorFields) {
            if (-not (Test-ShellForgeHexColor -Value $colorValue)) {
                [void]$errors.Add("Invalid hex color '$colorValue'.")
            }
        }

        if ($errors.Count -gt 0) {
            throw ('Theme validation failed:' + [Environment]::NewLine + ($errors -join [Environment]::NewLine))
        }

        return $Theme
    }
}

