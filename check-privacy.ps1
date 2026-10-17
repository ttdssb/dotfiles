# Scan this repo for personal data before pushing it anywhere.
#
# The script itself contains no private values. Put the words that matter to
# you (real name, student id, user name, host name, old paths ...) one per
# line in  privacy-patterns.local.txt  - that file is git-ignored.

$here = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

$rules = @(
    @{ name = 'hardcoded user path'; regex = $true; pattern = 'C:\\Users\\(?!<)[A-Za-z0-9._-]{2,}' }
    @{ name = 'ip address';          regex = $true; pattern = '\b\d{1,3}(\.\d{1,3}){3}\b' }
    @{ name = 'api key / token';     regex = $true; pattern = '(sk-[A-Za-z0-9]{16,}|ghp_[A-Za-z0-9]{20,}|gho_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16})' }
    @{ name = 'guid / device id';    regex = $true; pattern = '\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\b' }
)

$localFile = Join-Path $here 'privacy-patterns.local.txt'
$localCount = 0
if (Test-Path -LiteralPath $localFile) {
    Get-Content -LiteralPath $localFile | ForEach-Object {
        $v = $_.Trim()
        if ($v -and -not $v.StartsWith('#')) {
            $rules += @{ name = 'local keyword'; pattern = $v }
            $localCount++
        }
    }
}

Write-Host ("personal keywords loaded: " + $localCount) -ForegroundColor DarkGray

$files = Get-ChildItem -LiteralPath $here -Recurse -File |
         Where-Object {
             $_.FullName -notmatch '\\\.git\\' -and
             $_.Name -ne 'check-privacy.ps1' -and
             $_.Name -ne 'privacy-patterns.local.txt'
         }

$hits = 0
foreach ($f in $files) {
    $rel = $f.FullName.Substring($here.Length).TrimStart('\')
    $lines = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue
    for ($i = 0; $i -lt $lines.Count; $i++) {
        foreach ($r in $rules) {
            $text = $lines[$i]
            $found = if ($r.regex) { $text -match $r.pattern } else { $text.IndexOf($r.pattern, [StringComparison]::OrdinalIgnoreCase) -ge 0 }
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
    Write-Host ("clean - scanned " + $files.Count + " files") -ForegroundColor Green
} else {
    Write-Host ("found " + $hits + " possible personal item(s) - fix them before pushing") -ForegroundColor Yellow
}
