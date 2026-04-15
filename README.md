# SHELLFORGE

**ShellForge** est un module PowerShell orienté terminal UX qui vise a fournir un studio de theming sombre, un moteur de prompt natif, des sauvegardes sûres, une intégration de profil PowerShell et des workflows d’import/export/deploiement de themes.

GitHub short description:
`Cross-platform PowerShell theme studio and deployment engine with native prompt rendering, safe profile integration and recoverable backups.`

## Utilisation ultra simple

Si tu veux juste recuperer le code et charger le module, copie-colle seulement ca.

### Windows PowerShell ou PowerShell 7

Fais les lignes dans cet ordre.
Commence dans ton dossier utilisateur, pas dans `C:\Windows\System32`.

```powershell
Set-Location $HOME
git clone https://github.com/Z3PHIRE/ShellForge.git
Set-Location .\ShellForge
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Import-Module .\src\ShellForge\ShellForge.psd1 -Force
Get-Command -Module ShellForge
```

### Linux avec `pwsh`

Fais les lignes dans cet ordre.

```bash
cd ~
git clone https://github.com/Z3PHIRE/ShellForge.git
cd ShellForge
pwsh -NoProfile -Command "Import-Module ./src/ShellForge/ShellForge.psd1 -Force; Get-Command -Module ShellForge"
```

Si tu vois la liste des commandes ShellForge, c'est bon: le code est importe.

## Si tu as une erreur

### Erreur: `Impossible de trouver le chemin ...\ShellForge`

Tu as essaye d'entrer dans le dossier `ShellForge` avant de le telecharger.

Ordre correct:

```powershell
Set-Location $HOME
git clone https://github.com/Z3PHIRE/ShellForge.git
Set-Location .\ShellForge
```

### Erreur: `L’execution de scripts est desactivee sur ce systeme`

Sous Windows PowerShell, ajoute cette ligne avant `Import-Module`:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

Cette commande est temporaire:

- elle ne change rien pour tout le PC
- elle ne dure que pour la fenetre PowerShell en cours
- elle sert juste a laisser PowerShell charger le module

## Etat du depot

Le depot contient deja le socle du produit:

- module PowerShell structure (`src/ShellForge`)
- validation stricte du schema de theme
- moteur de prompt natif ShellForge
- integration PSReadLine
- sauvegarde et restauration des fichiers ShellForge
- integration sûre dans le profil PowerShell
- base du custom builder, du moteur UI et des packs `.sfpack`

Important: les presets JSON dans `themes/` ne sont pas encore ajoutes dans ce workspace. Les commandes qui appliquent un theme ont donc besoin qu'un theme soit ajoute avant utilisation.

## Vision produit

ShellForge a pour objectif d’apporter un vrai workflow “theme studio + deployment engine” pour PowerShell:

- appliquer un theme sombre premium a une session locale
- persister ce theme dans le profil PowerShell utilisateur
- restaurer rapidement un etat precedent
- proposer une couche UI numerique pour choisir ou construire un theme
- exporter/importer des packs de theme portables
- preparer un deploiement simple vers plusieurs machines
- fonctionner sans dependance obligatoire a Oh My Posh

## Fonctionnalites deja presentes dans le code

- `Get-ShellForgeTheme`
- `Test-ShellForgeTheme`
- `Use-ShellForgeTheme`
- `Install-ShellForgeTheme`
- `Import-ShellForgeProfile`
- `Backup-ShellForgeConfig`
- `Restore-ShellForgeConfig`

## Surface cible du module

Le manifest du module expose la surface cible suivante:

- `Invoke-ShellForge`
- `Get-ShellForgeTheme`
- `Install-ShellForgeTheme`
- `Use-ShellForgeTheme`
- `New-ShellForgeTheme`
- `Export-ShellForgeTheme`
- `Import-ShellForgeTheme`
- `Backup-ShellForgeConfig`
- `Restore-ShellForgeConfig`
- `Deploy-ShellForgeTheme`
- `Uninstall-ShellForge`

## Plateformes supportees

- PowerShell 7.x: cible principale
- Windows PowerShell 5.1: compatibilite best-effort
- Windows 10/11 et Windows Server 2022
- Linux avec `pwsh`

## Installation depuis la source

Depuis ce workspace:

```powershell
Import-Module .\src\ShellForge\ShellForge.psd1 -Force
```

Pour verifier les commandes chargees:

```powershell
Get-Command -Module ShellForge
```

## Commandes copier-coller

### Windows PowerShell ou PowerShell 7

Pour recuperer le code et charger le module:

```powershell
Set-Location $HOME
git clone https://github.com/Z3PHIRE/ShellForge.git
Set-Location .\ShellForge
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Import-Module .\src\ShellForge\ShellForge.psd1 -Force
Get-Command -Module ShellForge
```

Version en une seule ligne:

```powershell
Set-Location $HOME; git clone https://github.com/Z3PHIRE/ShellForge.git; Set-Location .\ShellForge; Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force; Import-Module .\src\ShellForge\ShellForge.psd1 -Force; Get-Command -Module ShellForge
```

### Linux avec `pwsh`

Pour recuperer le code et charger le module:

```bash
cd ~
git clone https://github.com/Z3PHIRE/ShellForge.git
cd ShellForge
pwsh -NoProfile -Command "Import-Module ./src/ShellForge/ShellForge.psd1 -Force; Get-Command -Module ShellForge"
```

Version encore plus courte:

```bash
cd ~ && git clone https://github.com/Z3PHIRE/ShellForge.git && cd ShellForge && pwsh -NoProfile -Command "Import-Module ./src/ShellForge/ShellForge.psd1 -Force; Get-Command -Module ShellForge"
```

### Import local sans GitHub

Si le code est deja present sur la machine cible:

```powershell
Import-Module C:\Path\To\ShellForge\src\ShellForge\ShellForge.psd1 -Force
```

Equivalent Linux:

```bash
pwsh -NoProfile -Command "Import-Module /opt/ShellForge/src/ShellForge/ShellForge.psd1 -Force; Get-Command -Module ShellForge"
```

### Deploiement prudent avec simulation

Quand un theme JSON sera ajoute dans `themes/`, utiliser `-WhatIf` avant toute ecriture dans le profil utilisateur:

```powershell
Import-Module .\src\ShellForge\ShellForge.psd1 -Force
Install-ShellForgeTheme -Path .\themes\<theme>.json -WhatIf
```

Equivalent Linux:

```bash
pwsh -NoProfile -Command "Import-Module ./src/ShellForge/ShellForge.psd1 -Force; Install-ShellForgeTheme -Path ./themes/<theme>.json -WhatIf"
```

## Bootstrap GitHub

Ligne bootstrap distante prevue pour le depot publie:

```powershell
irm https://raw.githubusercontent.com/Z3PHIRE/ShellForge/main/bootstrap.ps1 | iex
```

Alternative plus sure:

```powershell
$bootstrapPath = Join-Path $env:TEMP 'bootstrap-shellforge.ps1'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Z3PHIRE/ShellForge/main/bootstrap.ps1' -OutFile $bootstrapPath
Get-Content $bootstrapPath
pwsh -NoProfile -ExecutionPolicy Bypass -File $bootstrapPath
```

Note: dans ce workspace, `bootstrap.ps1` n'est pas encore ajoute. La ligne ci-dessus est donc l'URL finale a publier, pas encore une commande exploitable localement.

## Demarrage rapide

### Charger le module

```powershell
Import-Module .\src\ShellForge\ShellForge.psd1 -Force
Get-Command -Module ShellForge
```

### Voir les commandes disponibles

```powershell
Get-Command -Module ShellForge
```

### Sauvegarder avant modification

```powershell
Backup-ShellForgeConfig -WhatIf
Backup-ShellForgeConfig
```

### Restaurer le dernier etat

```powershell
Restore-ShellForgeConfig -Latest -WhatIf
Restore-ShellForgeConfig -Latest
```

## Comportement de sauvegarde

ShellForge suit une approche conservative:

- backup avant modification du profil utilisateur
- backup avant remplacement du theme courant
- backup des fichiers touches si un workflow etend plus tard l’integration terminal
- aucune modification silencieuse
- journalisation locale dans le repertoire de configuration ShellForge

Chemins typiques:

- Windows: `%LOCALAPPDATA%\ShellForge`
- Linux: `~/.config/shellforge`
- macOS: `~/Library/Application Support/shellforge`

## Integration du profil PowerShell

L’installation locale n’ecrase pas arbitrairement le profil. ShellForge insere un bloc gere avec des marqueurs dedies:

- `# >>> ShellForge Managed Block >>>`
- `# <<< ShellForge Managed Block <<<`

Le chargeur de profil ShellForge:

- importe le module
- recharge le theme courant
- applique les couleurs PSReadLine
- active le moteur natif ShellForge
- peut basculer vers Oh My Posh si l’outil et la config existent

## Oh My Posh

ShellForge n’en depend pas.

- si `oh-my-posh` n’est pas present: le prompt natif ShellForge reste utilisable
- si `oh-my-posh` est present: une config compatible peut etre generee
- la logique de fallback est explicite et journalisee

## Arborescence actuelle

```text
ShellForge/
|-- CHANGELOG.md
|-- LICENSE
|-- README.md
|-- src/
|   `-- ShellForge/
|       |-- ShellForge.psd1
|       |-- ShellForge.psm1
|       |-- Private/
|       `-- Public/
|-- themes/
|-- assets/
|   `-- previews/
|-- docs/
|-- examples/
`-- tests/
```

## Structure interne du module

- `Private/`
  - resolution de chemins cross-platform
  - schema et validation de theme
  - rendu natif du prompt
  - packs `.sfpack`
  - helpers de menu numerique
  - sauvegarde/restauration
- `Public/`
  - commandes d’administration et d’utilisation ShellForge

## Commandes disponibles aujourd’hui

### `Get-ShellForgeTheme`

Liste les themes du depot/local library ou retourne un theme specifique.

```powershell
Get-ShellForgeTheme
Get-ShellForgeTheme -Current
Get-ShellForgeTheme -Path .\themes\cyberglass.json
```

### `Test-ShellForgeTheme`

Valide un theme et retourne un resultat exploitable.

```powershell
Test-ShellForgeTheme -Path .\themes\<theme>.json
```

### `Use-ShellForgeTheme`

Applique un theme a la session courante sans persistance profil.

```powershell
Use-ShellForgeTheme -Path .\themes\<theme>.json
```

### `Install-ShellForgeTheme`

Persist le theme courant et injecte le bloc ShellForge dans le profil utilisateur.

```powershell
Install-ShellForgeTheme -Path .\themes\<theme>.json -UseOhMyPosh
```

### `Import-ShellForgeProfile`

Recharge le theme courant dans la session.

```powershell
Import-ShellForgeProfile
```

### `Backup-ShellForgeConfig`

Construit un snapshot restorable avant tout changement.

```powershell
Backup-ShellForgeConfig
```

### `Restore-ShellForgeConfig`

Restaure un backup specifique ou le plus recent.

```powershell
Restore-ShellForgeConfig -Latest
```

## Builder et TUI

Le code du depot contient deja:

- helpers de rendu console
- parsing numerique robuste
- squelette du custom builder interactif
- construction d’un objet de theme a partir de choix numeriques

Le prochain branchement consiste a exposer ce flux via `Invoke-ShellForge` et a y raccorder les presets officiels.

## Import / Export / Deploiement

Le moteur de pack `.sfpack` est deja present en interne:

- lecture securisee des archives
- rejection des entrees dangereuses
- prise en charge du `manifest.json`
- theme embarque
- asset de preview optionnel
- prompt config optionnelle

Les commandes publiques d’orchestration associées sont prevues:

- `Export-ShellForgeTheme`
- `Import-ShellForgeTheme`
- `Deploy-ShellForgeTheme`

## Tests

Le dossier `tests/` est reserve a la couverture Pester 5.x.

Commande cible:

```powershell
Invoke-Pester -Path .\tests
```

## Contribution

Principes retenus pour le depot:

- PowerShell strict
- separation claire public/prive
- erreurs actionnables
- ecriture idempotente
- backup systematique avant changement
- compatibilite cross-platform raisonnee

## Roadmap immediate

- ajouter les 9 presets officiels dans `themes/`
- exposer `Invoke-ShellForge` avec le menu numerique complet
- publier `bootstrap.ps1` et `uninstall.ps1`
- finaliser `Import/Export/Deploy`
- ajouter les previews SVG dans `assets/previews/`
- brancher la suite Pester

## License

Projet distribue sous licence MIT. Voir `LICENSE`.
