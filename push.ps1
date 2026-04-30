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
feat: full offline astrology engine — Swiss Ephemeris + Ashtakoota + AI horoscope

Root cause: Prokerala API was silently failing, showing hardcoded mock data
(Mesha lagna / Vrischika rasi) regardless of user's actual birth details.

Backend — zero external API dependency for core features:

requirements.txt:
  + pyswisseph==2.10.3.2 (Swiss Ephemeris Python binding)

services/astro_compute.py (NEW):
  - Computes all planet positions (sidereal, Lahiri ayanamsa), Ascendant/Lagna,
    Moon rasi, Nakshatra + pada directly via Swiss Ephemeris
  - Returns Prokerala-shaped dicts so existing service parsing works unchanged
  - Accurate for any birth date / location / timezone

services/astro_match.py (NEW):
  - Full Ashtakoota Guna Milan: all 8 kutas (Varna/Vashya/Tara/Yoni/Graha
    Maitri/Gana/Bhakoot/Nadi) with classical scoring rules, 36 pt total
  - Nakshatra data table (all 27) with Gana, Yoni, Varna, Nadi attributes
  - Planet friendship table for Graha Maitri
  - Nadi Dosha detection

astrology_repository.py:
  - _compute_chart(): Swiss Ephemeris first, Prokerala fallback, mock last resort

astrology_service.py:
  - English→Sanskrit rasi mapper + _parse_planets/_parse_summary fixes
  - get_match: computes both charts via Swiss Ephemeris, runs Ashtakoota
  - get_horoscope: Prokerala → AI-generated (OpenAI, sign+period specific) → static
  - get_muhurtham: computes real auspicious days via Moon nakshatra + tithi;
    dynamic fallback slots relative to requested date range

Flutter:
  - kundli_page.dart: fix compile error (KundliEntity.rasi not .summary.rasi)
  - kundli_page.dart: BlocConsumer dispatches MoonSignUpdated on KundliLoaded
  - auth_bloc.dart: MoonSignUpdated saves to SecureStorage + updates state
  - horoscope_page.dart: _initSignFromUser() opens correct Rasi from AuthBloc
"@

git commit -m $msg

# Pull remote changes (e.g. CI APK commits) then push
git pull origin master --rebase
git push origin master
Write-Host "Done!" -ForegroundColor Green
