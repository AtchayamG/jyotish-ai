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

# Remove Jyotish/ subfolder from git tracking and local disk (one-time cleanup)
if (Test-Path "Jyotish") {
  git rm -r --cached Jyotish/ 2>$null
  Remove-Item -Recurse -Force "Jyotish"
  Write-Host "Removed Jyotish/ subfolder" -ForegroundColor Yellow
}

git add -A

# Write commit message to a temp file to avoid Unicode/shell parsing issues
$msg = @"
fix: app icon correct path, horoscope period content, home spacing, Jyotish subfolder removed

App icon (correct git paths):
  - Icons now in correct flutter_app/android mipmap folders (not Jyotish subfolder)
  - All 5 densities: ic_launcher + ic_launcher_round + ic_launcher_foreground
  - mipmap-anydpi-v26/ic_launcher.xml + ic_launcher_round.xml (Android 8+)
  - values/colors.xml: ic_launcher_background = #060610

Horoscope - rich period-specific content:
  - Weekly: full Mon-Sun day-by-day breakdown per rasi
  - Monthly: career/finance/relationships/health/spiritual sections per rasi
  - Yearly: complete annual forecast with quarterly guidance per rasi
  - Daily predictions retained; horo_type now fully drives content

Home page:
  - Removed excess bottom padding (x3l -> lg) below Quick Actions

Repo cleanup:
  - Removed Jyotish/ subfolder from git tracking and local disk
"@

$tmpFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmpFile, $msg, [System.Text.Encoding]::UTF8)
git commit -F $tmpFile
Remove-Item $tmpFile -Force

# Pull remote changes then push
git pull origin master --rebase
git push origin master
Write-Host "Done!" -ForegroundColor Green
