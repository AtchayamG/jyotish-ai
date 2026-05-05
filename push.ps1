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
feat: AI kundli chat, date-aware horoscopes, home page redesign

AI Chatbot - personalized with real birth chart:
  - Computes full Vedic chart via Swiss Ephemeris on every chat request
  - Injects lagna, rasi, nakshatra, all 9 planet positions into system prompt
  - Implements Vimshottari dasha calculator: correct mahadasha + antardasha with dates
  - Rule-based fallback now answers lagna/rasi/nakshatra/dasha from actual chart
  - CRITICAL RULES force AI to never give generic responses; always reference user chart
  - max_tokens raised to 800 for richer chart-based answers

Horoscope - dynamically date-aware:
  - Daily: 3 variants per rasi, rotates deterministically by calendar date (hashlib seed)
  - Weekly: actual date range in prediction header (e.g. '5-11 May 2026')
  - Monthly: current month name prepended to prediction
  - Daily scores jitter slightly per day (+/-0.5) for realism
  - AI path (OpenAI): passes full date string + ISO week number for genuinely unique GPT content
  - date_range fields now show real dates instead of 'Today / This Week / This Month'

Home page redesign - astrological features replace Quick Actions:
  - REMOVED: Quick Actions grid (redundant with bottom nav bar)
  - ADDED: Today's Cosmic Snapshot card - day lord, planet symbol, focus theme
  - ADDED: Moon Phase card - live phase calculation from Julian Day, days to next event
  - ADDED: Daily Mantra card - planet mantra for the day (108x chanting reminder)
  - ADDED: Auspicious Times card - Brahma Muhurta, Abhijit Muhurta, Rahu Kaal per weekday
  - ADDED: Your Chart card - moon sign, birth place, DOB pills + link to full Kundli
"@

$tmpFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmpFile, $msg, [System.Text.Encoding]::UTF8)
git commit -F $tmpFile
Remove-Item $tmpFile -Force

# Pull remote changes then push
git pull origin master --rebase
git push origin master
Write-Host "Done!" -ForegroundColor Green
