# Prise En Main ShellForge

Ce guide explique **comment installer, mettre a jour et utiliser ShellForge** sans se perdre dans les details.

## La commande la plus simple

La meme commande sert a:

- installer ShellForge la premiere fois
- mettre a jour ShellForge plus tard

### Windows PowerShell ou PowerShell 7

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
irm https://raw.githubusercontent.com/Z3PHIRE/ShellForge/main/bootstrap.ps1 | iex
```

### Linux avec `pwsh`

```bash
pwsh -NoProfile -Command "irm https://raw.githubusercontent.com/Z3PHIRE/ShellForge/main/bootstrap.ps1 | iex"
```

## Ce que fait cette commande

Le script `bootstrap.ps1`:

1. telecharge le depot `ShellForge` dans ton dossier utilisateur si le dossier n'existe pas
2. met a jour le depot si le dossier existe deja
3. charge le module PowerShell
4. te montre les commandes suivantes a lancer

## Ou le code est installe

Par defaut, ShellForge est installe ici:

- Windows: `C:\Users\<TonNom>\ShellForge`
- Linux: `~/ShellForge`

## Verifier que tout est bon

Dans PowerShell:

```powershell
Get-Command -Module ShellForge
```

Si tu vois les commandes ShellForge, c'est bon.

## La commande la plus simple pour utiliser ShellForge

```powershell
shellforge
```

Cette commande ouvre le menu interactif ShellForge.

Tu peux alors:

- choisir un theme
- voir son apercu
- l'appliquer a la session en cours
- l'installer dans ton profil PowerShell

## Voir les themes disponibles

```powershell
Get-ShellForgeTheme
```

Themes integres:

- CyberGlass
- Arctic Void
- Red Tactical
- Neon Grid
- Obsidian Nord
- Amber SOC
- Purple Forge
- Graphite Pulse
- Eclipse Matrix

## Appliquer un theme rapidement

### Methode interactive

```powershell
Use-ShellForgeTheme
```

ShellForge te laisse choisir un theme dans une liste.

### Methode directe

```powershell
Use-ShellForgeTheme -Name CyberGlass
```

## Installer un theme dans ton profil

### Methode interactive

```powershell
Install-ShellForgeTheme
```

### Methode directe

```powershell
Install-ShellForgeTheme -Name "Arctic Void"
```

Avant d'ecrire dans le profil, tu peux tester sans rien modifier:

```powershell
Install-ShellForgeTheme -Name "Arctic Void" -WhatIf
```

## Verifier tous les themes

```powershell
Test-ShellForgeTheme
```

Cette commande valide tous les themes integres.

Pour un theme precis:

```powershell
Test-ShellForgeTheme -Path .\themes\cyberglass.json
```

## Sauvegarder avant changement

```powershell
Backup-ShellForgeConfig
```

## Restaurer le dernier etat

```powershell
Restore-ShellForgeConfig -Latest
```

## Mettre a jour plus tard

Relance simplement la meme commande qu'au debut:

### Windows

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
irm https://raw.githubusercontent.com/Z3PHIRE/ShellForge/main/bootstrap.ps1 | iex
```

### Linux

```bash
pwsh -NoProfile -Command "irm https://raw.githubusercontent.com/Z3PHIRE/ShellForge/main/bootstrap.ps1 | iex"
```

## Si une commande ne marche pas

### Execution policy bloquee sous Windows

Ajoute cette ligne avant l'import du module:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

### Le module n'est pas charge dans la fenetre actuelle

Recharge-le:

```powershell
Import-Module "$HOME\ShellForge\src\ShellForge\ShellForge.psd1" -Force
```

### Linux

```bash
pwsh -NoProfile -Command "Import-Module ~/ShellForge/src/ShellForge/ShellForge.psd1 -Force"
```

## Comment ShellForge fonctionne

ShellForge repose sur 4 idees simples:

1. un theme = un fichier JSON
2. appliquer un theme = changer le prompt et les couleurs de la session
3. installer un theme = lier ce theme au profil PowerShell utilisateur
4. restaurer = remettre l'etat sauvegarde avant modification

## Fichiers utiles

- `README.md` : vue d'ensemble
- `docs/PRISE-EN-MAIN.md` : guide simple
- `themes/` : themes JSON integres
- `bootstrap.ps1` : installation et mise a jour
- `src/ShellForge/` : code du module
