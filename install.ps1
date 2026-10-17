$ErrorActionPreference = 'Continue'

function Say([string]$m) { Write-Host $m }
function Ok([string]$m) { Write-Host ("  [OK] " + $m) -ForegroundColor Green }
function Warn([string]$m) { Write-Host ("  [!!] " + $m) -ForegroundColor Yellow }

$here = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$home_ = $env:USERPROFILE

Write-Host "==============================================" -ForegroundColor Magenta
Write-Host "  dotfiles installer" -ForegroundColor Magenta
Write-Host "==============================================" -ForegroundColor Magenta
Say ""

# ---- execution policy (profiles are blocked under Restricted) ----
$eff = Get-ExecutionPolicy
if ($eff -in 'Restricted', 'AllSigned') {
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        Ok "execution policy -> RemoteSigned (current user)"
    } catch {
        Warn ("cannot change policy: " + $_.Exception.Message)
        Say  "   run: Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
    }
} else {
    Ok ("execution policy already allows scripts (" + $eff + ")")
}

# ---- powershell profile ----
$target = Join-Path $home_ '.dotfiles'
New-Item -ItemType Directory -Path $target -Force | Out-Null
Copy-Item -Path (Join-Path $here 'powershell\profile.ps1') -Destination (Join-Path $target 'profile.ps1') -Force
Ok ("profile copied to " + $target)

$profileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
if (Test-Path $PROFILE) {
    Copy-Item -LiteralPath $PROFILE -Destination ($PROFILE + '.bak-' + (Get-Date -Format 'yyyyMMdd-HHmmss')) -Force
}
$line = '. "' + (Join-Path $target 'profile.ps1') + '"'
if (-not (Select-String -Path $PROFILE -SimpleMatch 'dotfiles\profile.ps1' -Quiet -ErrorAction SilentlyContinue)) {
    Add-Content -LiteralPath $PROFILE -Value ""
    Add-Content -LiteralPath $PROFILE -Value "# --- dotfiles ---"
    Add-Content -LiteralPath $PROFILE -Value $line
    Ok "profile hooked (takes effect in a new window)"
} else {
    Ok "profile already hooked"
}

# ---- vscode settings (merge only if it is plain JSON) ----
$vsPath = Join-Path $env:APPDATA 'Code\User\settings.json'
$fragment = Join-Path $here 'vscode\settings.json'
if ((Test-Path $vsPath) -and (Test-Path $fragment)) {
    try {
        $cur = Get-Content -LiteralPath $vsPath -Raw | ConvertFrom-Json -ErrorAction Stop
        $add = Get-Content -LiteralPath $fragment -Raw | ConvertFrom-Json -ErrorAction Stop
        Copy-Item -LiteralPath $vsPath -Destination ($vsPath + '.bak-' + (Get-Date -Format 'HHmmss')) -Force
        foreach ($p in $add.PSObject.Properties) {
            $cur | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force
        }
        $cur | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $vsPath -Encoding UTF8
        Ok "VS Code settings merged"
    } catch {
        Warn ("VS Code settings not touched (" + $_.Exception.Message + ")")
        Say  "  -> paste the keys from vscode\settings.json manually"
    }
} else {
    Warn "VS Code settings.json not found - skipped"
}

# ---- terminal ----
Say ""
Say "Windows Terminal: open Settings -> Open JSON file and paste the object from"
Say ("  " + (Join-Path $here 'terminal\catppuccin-macchiato.json'))
Say "into the  ""schemes"": [ ... ]  array, then set it as default colour scheme."

Say ""
Ok "done. close every PowerShell window and open a new one."
