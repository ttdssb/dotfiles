# Scan this repo for personal data before pushing it anywhere.

$here = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

# the real name is built from code points so this file stays pure ASCII
# (Windows PowerShell reads .ps1 files as ANSI and would choke on CJK literals)
$realName = -join ([char]0x7A0B, [char]0x5929, [char]0x4F51)

$rules = @(
    @{ name = 'real name';            pattern = $realName }
    @{ name = 'student id';           pattern = '2026313013' }
    @{ name = 'windows username';     pattern = 'Cxesty' }
    @{ name = 'hostname';             pattern = 'CXESTYLAPTOP' }
    @{ name = 'profile folder name';  pattern = '19520' }
    @{ name = 'hardcoded user path';  regex = $true; pattern = 'C:\\Users\\(?!<)[A-Za-z0-9._-]{2,}' }
    @{ name = 'ip address';           regex = $true; pattern = '\b\d{1,3}(\.\d{1,3}){3}\b' }
    @{ name = 'e-mail';               regex = $true; pattern = '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' }
    @{ name = 'api key / token';      regex = $true; pattern = '(sk-[A-Za-z0-9]{16,}|ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16})' }
    @{ name = 'guid / device id';     regex = $true; pattern = '\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\b' }
)

$files = Get-ChildItem -LiteralPath $here -Recurse -File |
         Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.Name -ne 'check-privacy.ps1' }

$hits = 0
foreach ($f in $files) {
    $rel = $f.FullName.Substring($here.Length).TrimStart('\')
    $lines = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue
    for ($i = 0; $i -lt $lines.Count; $i++) {
        foreach ($r in $rules) {
            $text = $lines[$i]
            $found = if ($r.regex) { $text -match $r.pattern } else { $text -like ('*' + $r.pattern + '*') }
            if ($found) {
                $hits++
                Write-Host ("  [HIT] " + $rel + ":" + ($i + 1) + "  (" + $r.name + ")") -ForegroundColor Red
                Write-Host ("        " + $text.Trim())
            }
        }
    }
}

Write-Host ""
if ($hits -eq 0) {
    Write-Host ("clean - scanned " + $files.Count + " files, nothing personal found") -ForegroundColor Green
} else {
    Write-Host ("found " + $hits + " possible personal item(s) - fix them before pushing") -ForegroundColor Yellow
}
