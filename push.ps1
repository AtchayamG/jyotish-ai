# push.ps1  — reusable commit+push script
# Usage: .\push.ps1
# Edit $msg below to change the commit message before running.

Set-Location "D:\Work\Claude\Jyotish"

$lock = ".git\index.lock"
if (Test-Path $lock) { Remove-Item $lock -Force }

git config user.email "atchayamganesh@gmail.com"
git config user.name  "Atchayam"

# ── Remove junk files from git tracking (safe even if already removed) ──
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
    git rm --cached $f 2>$null   # remove from index even if already deleted on disk
  }
}

git add -A

$msg = @"
fix: correct Kundli parsing, horoscope sign init, moon sign dashboard

Backend (astrology_service.py):
- Add English→Sanskrit rasi mapper (_EN_TO_RASI / _to_rasi())
- _parse_planets: use 'planet_position' key (Prokerala) with 'planets' fallback (mock)
- _parse_planets: convert English rasi names (Aries→Mesha etc.) for all planets + lagna
- _parse_summary: accept chart param; get lagna from ascendant.name (English, Prokerala)
  or ascendant.rasi.name (Sanskrit, mock fallback)
- _parse_summary: derive moon sign (Rasi) from moon_sign.name, or Moon planet rasi,
  or legacy rasi key — in that priority order

Flutter (horoscope_page.dart):
- Import AuthBloc; call _initSignFromUser() in initState()
- _initSignFromUser reads moonSign from AuthBloc and sets _idx to the correct sign,
  so the horoscope opens on the user's Rasi instead of always defaulting to Mesha

Flutter (auth_bloc.dart):
- Add MoonSignUpdated event + _onMoonSignUpdated handler
- Handler saves moon sign to SecureStorage + emits updated AuthAuthenticated state
  so the home dashboard chip updates without a re-login

Flutter (kundli_page.dart):
- Switch _buildChart from BlocBuilder → BlocConsumer
- On KundliLoaded, dispatch MoonSignUpdated(k.summary.rasi) to AuthBloc
"@

git commit -m $msg

# Pull remote changes (e.g. CI APK commits) then push
git pull origin master --rebase
git push origin master
Write-Host "Done!" -ForegroundColor Green
