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
feat: replace Prokerala with Swiss Ephemeris for accurate chart computation

Root cause: Prokerala API was silently returning empty responses, causing the
app to always show hardcoded mock data (Mesha lagna / Vrischika rasi) instead
of the user's actual birth chart.

Backend:
- Add pyswisseph==2.10.3.2 to requirements.txt (same engine Prokerala uses)
- New services/astro_compute.py: compute planet positions, Ascendant (Lagna),
  Moon sign (Rasi), Nakshatra+pada directly using Swiss Ephemeris + Lahiri
  ayanamsa — no external API required, works offline, accurate for any DOB
- astrology_repository.py: _compute_chart() calls Swiss Ephemeris first;
  Prokerala is now a fallback; mock data is last resort
- astrology_service.py: English→Sanskrit mapper (_EN_TO_RASI/_to_rasi()),
  _parse_planets uses planet_position key + converts English rasi names,
  _parse_summary gets Lagna from ascendant.name and Moon rasi from Moon planet
  or moon_sign key

Flutter:
- horoscope_page.dart: _initSignFromUser() initialises sign picker from
  AuthBloc moonSign so horoscope opens on user's actual Rasi (not Mesha)
- auth_bloc.dart: MoonSignUpdated event saves moon sign to SecureStorage and
  updates AuthAuthenticated state immediately
- kundli_page.dart: BlocConsumer dispatches MoonSignUpdated after KundliLoaded
  so home dashboard moon sign chip refreshes without re-login
"@

git commit -m $msg

# Pull remote changes (e.g. CI APK commits) then push
git pull origin master --rebase
git push origin master
Write-Host "Done!" -ForegroundColor Green
