# Windows dotfiles

My Windows 11 setup: Catppuccin everywhere, a ruffled JetBrainsMono terminal,
a gradient prompt and a few modern CLI tools.

Nothing here is machine specific — every path is resolved at runtime, so the
repo can be cloned onto any Windows box.

---

## What's inside

| Path | Purpose |
|---|---|
| `powershell/profile.ps1` | gradient prompt, `omfetch` system card, PSReadLine colours |
| `terminal/catppuccin-macchiato.json` | Windows Terminal colour scheme |
| `vscode/settings.json` | editor / theme / font preferences |
| `install.ps1` | deploys the two configs above into `%USERPROFILE%` |
| `check-privacy.ps1` | scans this repo for personal data before you push |

## Install

```powershell
git clone <this-repo> dotfiles
cd dotfiles
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Then close every PowerShell window and open a new one.

## What it looks like

```
   /\_/\     catppuccin shell   2026-01-01  09:41
  ( o.o )    user <you>  on  <host>
   > ^ <     try: omfetch / le / ll / lt / bat / rg / z

╭ 🐱 <you>@<host>  ·  ~/code  ·  ⎇ main
╰❯
```

> Add your own screenshot here.

## Before you push

```powershell
powershell -ExecutionPolicy Bypass -File .\check-privacy.ps1
```

It looks for real names, student ids, usernames, hostnames, hardcoded
`C:\Users\<something>` paths, IPs, e-mails and common token formats.
Everything it finds is printed with file and line number.

Keep the repository **private** and commit with a noreply address:

```powershell
git config user.email "<id>+<username>@users.noreply.github.com"
```

## License

Do whatever you want with it.
