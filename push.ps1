# push.ps1  — reusable commit+push script
# Usage: powershell -ExecutionPolicy Bypass -File .\push.ps1
# Edit $msg below to change the commit message before running.

Set-Location "D:\Work\Claude\Jyotish"

$lock = ".git\index.lock"
if (Test-Path $lock) { Remove-Item $lock -Force }

git config user.email "atchayamganesh@gmail.com"
git config user.name  "Atchayam"

# Remove junk files from git tracking (safe even if already removed)
$junk = @(
  "DELETE_OLD_GRADLE.bat",
  "DELETE_OLD_GRADLE_FILES.bat",
  "FIX_ANDROID.ps1",
  "GIT_CLEANUP_COMMANDS.md",
  "NUCLEAR_FIX.ps1",
  "PUSH_FRESH_STEPS.md",
  "REGENERATE_ANDROID.ps1",
  "RENDER_ENV_UPDATE.md",
  "SETUP_GITHUB_PAGES.md",
  "SWAGGER_GUIDE.md"
)
foreach ($f in $junk) {
  if (Test-Path $f) {
    git rm --cached $f 2>$null
    Remove-Item $f -Force 2>$null
  } else {
    git rm --cached $f 2>$null
  }
}

git add -A

# Write commit message to a temp file to avoid Unicode/shell parsing issues
$msg = @"
feat: app icon + splash bar loader

App icon:
  - Generated Jyotish AI icon (crescent moon + concentric rings, gold/violet/teal)
  - Written to all 5 Android mipmap densities (mdpi through xxxhdpi)
  - ic_launcher.png and ic_launcher_round.png both updated
  - Source 1024x1024 PNG saved to assets/icons/app_icon.png
  - pubspec.yaml: declare assets/icons/ folder

Splash screen:
  - Replaced 3-dot pulsing loader with 5-bar animated bar loader
  - Bars animate height 6px to 24px with staggered delays (mirror pattern)
  - Center bar gold, adjacent bars violet, outer bars teal for depth
"@

$tmpFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmpFile, $msg, [System.Text.Encoding]::UTF8)
git commit -F $tmpFile
Remove-Item $tmpFile -Force

# Pull remote changes then push
git pull origin master --rebase
git push origin master
Write-Host "Done!" -ForegroundColor Green
