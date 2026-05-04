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
feat: app icon, bar loader, routing fixes, horoscope tabs, home redesign

App icon:
  - Custom crescent moon icon (gold/violet/teal rings, dark background)
  - All 5 mipmap densities + ic_launcher_round + adaptive icon support
  - mipmap-anydpi-v26 XML + ic_launcher_foreground for Android 8+
  - values/colors.xml with ic_launcher_background (#060610)
  - assets/icons/app_icon.png source file + pubspec.yaml declaration

Splash / routing fixes:
  - app_router.dart: splash route never auto-redirected by GoRouter
    (SplashPage owns its own lifecycle + 3s minimum)
  - Login loading no longer jumps to splash (AuthLoading stays on login page)
  - Eliminated double-splash flash on reopen for logged-in users
  - splash_page.dart: replaced 3-dot loader with 5-bar animated bar loader

Home screen:
  - Forecast prediction text no longer truncated at 130 chars (full text shown)
  - Action cards redesigned: horizontal icon+text layout, aspect ratio 2.1
    (was 1.5 vertical stack) for compact and clean look

Horoscope page:
  - Period selector moved from AppBar compact toggles to full TabBar
  - Tabs: Today / Weekly / Monthly / Yearly with gold indicator
  - Content (prediction, scores, lucky factors, do/avoid) responds to tab

No Connection page:
  - Content now truly vertically centered (ConstrainedBox with minHeight)
"@

$tmpFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmpFile, $msg, [System.Text.Encoding]::UTF8)
git commit -F $tmpFile
Remove-Item $tmpFile -Force

# Pull remote changes then push
git pull origin master --rebase
git push origin master
Write-Host "Done!" -ForegroundColor Green
