# Hermes Quake Console installer for Windows Terminal.
# Merges the "Hermes Console" profile + Alt+` global summon action into the
# caller's existing Windows Terminal settings.json (backup made first).
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1 [-AutoStart] [-SettingsPath <path>]
#
#   -AutoStart      also create a Startup shortcut that seeds+minimizes the
#                   quake window at logon (recommended).
#   -SettingsPath   override target settings.json (for testing/dry runs).

param(
    [switch]$AutoStart,
    [string]$SettingsPath
)

$ErrorActionPreference = "Stop"

# ---- locate settings.json ----------------------------------------------------
if (-not $SettingsPath) {
    $localState = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    if (-not (Test-Path $localState)) {
        throw "Windows Terminal (Store package) not found. Install it from the Microsoft Store first."
    }
    $SettingsPath = Join-Path $localState "settings.json"
}
if (-not (Test-Path $SettingsPath)) { throw "settings.json not found at $SettingsPath" }

Write-Host "Target: $SettingsPath"

# ---- paths used by the profile ------------------------------------------------
$hermesExe = Join-Path $env:LOCALAPPDATA "hermes\hermes-agent\venv\Scripts\hermes.exe"
if (-not (Test-Path $hermesExe)) {
    throw "Hermes launcher not found at $hermesExe. Install Hermes Agent first, or edit `$hermesExe in this script."
}
$iconPath = Join-Path $env:LOCALAPPDATA "hermes\hermes-agent\web\public\favicon.ico"
if (-not (Test-Path $iconPath)) { $iconPath = $null }   # icon is optional

# ---- backup -------------------------------------------------------------------
$stamp  = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item $SettingsPath "$SettingsPath.bak-hermes-quake-$stamp"
Write-Host "Backup written: $SettingsPath.bak-hermes-quake-$stamp"

# ---- load + merge -------------------------------------------------------------
$json = Get-Content $SettingsPath -Raw | ConvertFrom-Json

$guid = "{586A99D2-0A4A-44E2-85D4-DA97776B93A1}"   # stable id for this integration

# profile
if ($json.profiles.list | Where-Object { $_.guid -eq $guid }) {
    Write-Host "Hermes Console profile already present - skipping."
} else {
    $profile = [ordered]@{
        name              = "Hermes Console"
        guid              = $guid
        commandline       = $hermesExe
        startingDirectory = "%USERPROFILE%"
        background        = "#0C0C1E"
        opacity           = 85
        padding           = "8"
        scrollbarState    = "hidden"
        hidden            = $false
    }
    if ($iconPath) { $profile.icon = $iconPath }
    if (-not $json.profiles.defaults.font.face) {
        # only suggest a font if none inherited; harmless if absent locally
        $profile.font = @{ face = "Cascadia Mono"; size = 12 }
    }
    $json.profiles.list = @($json.profiles.list) + @([pscustomobject]$profile)
    Write-Host "Added 'Hermes Console' profile."
}

# global summon action + keybinding
$actionId = "User.HermesQuakeToggle"
$hasAction = $json.actions | Where-Object { $_.id -eq $actionId }
$hasBinding = $json.keybindings | Where-Object { $_.id -eq $actionId }
if (-not $hasAction) {
    $action = [pscustomobject][ordered]@{
        id      = $actionId
        keys    = 'alt+`'
        name    = "Toggle Hermes Quake Drop-down"
        command = [pscustomobject][ordered]@{
            action            = "globalSummon"
            name              = "_quake"
            dropdownDuration  = 200
            toggleVisibility  = $true
            monitor           = "toMouse"
            desktop           = "toCurrent"
        }
    }
    $json.actions = @($json.actions) + @($action)
    Write-Host "Added globalSummon action."
}
if (-not $hasBinding) {
    if ($null -eq $json.keybindings) { $json.keybindings = @() }
    $json.keybindings = @($json.keybindings) + @([pscustomobject]@{ id = $actionId })
    Write-Host "Bound alt+grave."
}

# ---- write back (UTF-8, no BOM) ----------------------------------------------
$out = $json | ConvertTo-Json -Depth 32
[System.IO.File]::WriteAllText($SettingsPath, $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Settings updated."

# ---- optional: logon seeder ---------------------------------------------------
if ($AutoStart) {
    $seedScript = Join-Path $env:USERPROFILE "bin\seed-hermes-quake.ps1"
    Copy-Item (Join-Path $PSScriptRoot "seed-hermes-quake.ps1") $seedScript -Force

    $startup = [Environment]::GetFolderPath("Startup")
    $lnkPath = Join-Path $startup "Hermes Quake Seeder.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut($lnkPath)
    $lnk.TargetPath = "powershell.exe"
    $lnk.Arguments  = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$seedScript`""
    $lnk.Description = "Seed the Windows Terminal quake window with Hermes at logon"
    $lnk.Save()
    Write-Host "Startup shortcut created: $lnkPath"
}

Write-Host ""
Write-Host "Done. Restart Windows Terminal, then press Alt+grave to drop the console."
