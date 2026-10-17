# Catppuccin Macchiato prompt for PowerShell 5.1 / 7
# Source is ASCII-only on purpose: Windows PowerShell reads .ps1 as ANSI,
# so the fancy glyphs are built from code points at runtime.

$script:CP = @{
    rosewater = @(245, 224, 220); flamingo = @(242, 205, 205)
    pink      = @(245, 194, 231); mauve    = @(203, 166, 247)
    red       = @(243, 139, 168); peach    = @(250, 179, 135)
    yellow    = @(249, 226, 175); green    = @(166, 227, 161)
    teal      = @(148, 226, 213); sky      = @(137, 220, 235)
    sapphire  = @(116, 199, 236); blue     = @(137, 180, 250)
    lavender  = @(180, 190, 254)
    text      = @(202, 211, 245); subtext  = @(166, 173, 200)
    overlay   = @(108, 112, 134); surface  = @(54, 58, 79)
}

$script:GL = @{
    Top    = [string][char]0x256D
    Bottom = [string][char]0x2570
    Dot    = [string][char]0x00B7
    Arrow  = [string][char]0x276F
    Branch = [string][char]0x2387
    Cat    = [char]::ConvertFromUtf32(0x1F431)
}

function Get-AnsiFg([int[]]$rgb) { "$([char]27)[38;2;$($rgb[0]);$($rgb[1]);$($rgb[2])m" }
$script:AnsiReset = "$([char]27)[0m"

function Get-Gradient([string]$text, [int[]]$a, [int[]]$b) {
    if ($text.Length -eq 0) { return '' }
    $out = ''
    for ($i = 0; $i -lt $text.Length; $i++) {
        $t = if ($text.Length -le 1) { 0 } else { $i / ($text.Length - 1) }
        $r  = [int]($a[0] + ($b[0] - $a[0]) * $t)
        $g  = [int]($a[1] + ($b[1] - $a[1]) * $t)
        $bl = [int]($a[2] + ($b[2] - $a[2]) * $t)
        $out += "$([char]27)[38;2;$r;$g;${bl}m$($text[$i])"
    }
    return $out + $script:AnsiReset
}

function Get-GitBranch {
    try {
        $b = & git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $b) { return "$b" }
    } catch { }
    return $null
}

function prompt {
    $lastExit = $LASTEXITCODE

    $cwd = (Get-Location).Path
    if ($cwd.StartsWith($env:USERPROFILE)) {
        $cwd = '~' + $cwd.Substring($env:USERPROFILE.Length)
    }

    $branch = Get-GitBranch
    $user   = "$env:USERNAME@$env:COMPUTERNAME"

    $top  = Get-Gradient $user $script:CP.pink $script:CP.mauve
    $path = Get-Gradient $cwd  $script:CP.sapphire $script:CP.blue
    $sep  = (Get-AnsiFg $script:CP.overlay) + '  ' + $script:GL.Dot + '  ' + $script:AnsiReset

    $line1 = (Get-AnsiFg $script:CP.overlay) + $script:GL.Top + ' ' + $script:AnsiReset + $script:GL.Cat + ' ' + $top + $sep + $path
    if ($branch) {
        $line1 += $sep + (Get-AnsiFg $script:CP.green) + $script:GL.Branch + ' ' + $branch + $script:AnsiReset
    }

    $arrowColour = if ($null -eq $lastExit -or $lastExit -eq 0) { $script:CP.mauve } else { $script:CP.red }
    $line2 = (Get-AnsiFg $script:CP.overlay) + $script:GL.Bottom + $script:AnsiReset + (Get-AnsiFg $arrowColour) + $script:GL.Arrow + ' ' + $script:AnsiReset

    return ($line1 + "`n" + $line2)
}

# omfetch - small system card, no external tools required
function omfetch {
    $cv  = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue
    $os  = if ($cv) { "$($cv.DisplayVersion) ($($cv.CurrentBuild).$($cv.UBR))" } else { 'Windows' }
    $cpu = try { (Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0').ProcessorNameString.Trim() } catch { 'CPU' }

    $ram = 'n/a'
    try {
        $b = (Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).TotalPhysicalMemory
        $ram = [math]::Round($b / 1GB, 1).ToString() + ' GB'
    } catch { }

    $gpu = 'n/a'
    try {
        $g = Get-CimInstance Win32_VideoController -ErrorAction Stop | ForEach-Object { $_.Name }
        if ($g) { $gpu = ($g -join ' + ') }
    } catch { }

    $uptime = 'n/a'
    try {
        $wos = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $up  = (Get-Date) - $wos.LastBootUpTime
        $uptime = '{0}h {1}m' -f [int]$up.TotalHours, $up.Minutes
    } catch { }

    $disk = 'n/a'
    try {
        $v = Get-Volume -DriveLetter C -ErrorAction Stop
        $disk = '{0} GB free' -f [math]::Round($v.SizeRemaining / 1GB, 1)
    } catch {
        try {
            $dc = Get-PSDrive -Name C -ErrorAction Stop
            if ($dc.Free -gt 0) { $disk = '{0} GB free' -f [math]::Round($dc.Free / 1GB, 1) }
        } catch { }
    }

    $py = try { (Get-Command python -ErrorAction Stop).Source } catch { 'not on PATH' }

    $cat = @(
        '   /\_/\  ',
        '  ( o.o ) ',
        '   > ^ <  '
    )
    $info = @(
        ('OS      ' + $os),
        ('Host    ' + $env:COMPUTERNAME),
        ('CPU     ' + $cpu),
        ('Threads ' + $env:NUMBER_OF_PROCESSORS),
        ('RAM     ' + $ram),
        ('GPU     ' + $gpu),
        ('Disk    ' + $disk),
        ('Uptime  ' + $uptime),
        ('Python  ' + $py)
    )

    $rows  = [Math]::Max($cat.Count, $info.Count)
    $mauve = Get-AnsiFg $script:CP.mauve
    $pink  = Get-AnsiFg $script:CP.pink
    $reset = $script:AnsiReset

    Write-Host ''
    for ($i = 0; $i -lt $rows; $i++) {
        $left  = if ($i -lt $cat.Count) { $pink + $cat[$i] + $reset } else { '         ' }
        $right = if ($i -lt $info.Count) { $info[$i] } else { '' }
        Write-Host ($left + '  ' + $mauve + $right + $reset)
    }
    Write-Host ''
}

# PSReadLine colours (completion list, history search)
try {
    Set-PSReadLineOption -Colors @{
        Command   = '#f5c2e7'
        Parameter = '#cba6f7'
        String    = '#a6e3a1'
        Variable  = '#f2cdcd'
        Number    = '#fab387'
        Comment   = '#6c7086'
        Keyword   = '#89b4fa'
        Operator  = '#94e2d5'
        Type      = '#f9e2af'
        Member    = '#89dceb'
        Selection = '#585b70'
    } -ErrorAction SilentlyContinue
} catch { }

try { $Host.UI.RawUI.WindowTitle = "$env:COMPUTERNAME  -  $((Get-Location).Path)" } catch { }

# small welcome banner (delete the Show-KitBanner call below to turn it off)
function Show-KitBanner {
    $d = Get-Date
    $pink  = Get-AnsiFg $script:CP.pink
    $mauve = Get-AnsiFg $script:CP.mauve
    $reset = $script:AnsiReset
    $cat = @(
        '   /\_/\  ',
        '  ( o.o ) ',
        '   > ^ <  '
    )
    $info = @(
        ('catppuccin shell   ' + $d.ToString('yyyy-MM-dd  HH:mm')),
        ('user ' + $env:USERNAME + '  on  ' + $env:COMPUTERNAME),
        'try: omfetch / le / ll / lt / bat / rg / z'
    )
    Write-Host ''
    for ($i = 0; $i -lt 3; $i++) {
        Write-Host ($pink + $cat[$i] + $reset + '   ' + $mauve + $info[$i] + $reset)
    }
    Write-Host ''
}
Show-KitBanner
