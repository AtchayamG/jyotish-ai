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
fix: moon sign on home screen, horoscope content, Android build

Android build:
  - gradle.properties: disable Jetifier (fails on Java-21 jars), disable
    Kotlin incremental (Windows path conflict in daemon)
  - gradle-wrapper.properties: upgrade Gradle 8.4 to 8.9 (Java 21 compat)
  - app/build.gradle.kts: Java/Kotlin target 1.8 to 11

Backend:
  - astrology_service.py: import http_client at module level (was NameError
    inside _ai_horoscope causing AI fallback to silently fail)
  - astrology_repository.py: expand _mock_horoscope to all 12 rasis with
    proper per-rasi predictions, lucky factors, scores and do/avoid lists

Flutter - moon sign on home screen:
  - auth_remote_datasource.dart: add fetchProfile() -> GET /user/profile
  - auth_bloc.dart: _onCheck silently fetches moon sign from backend when
    local storage has no moon sign but user has birth details

Flutter - horoscope page redesign:
  - horoscope_remote_datasource.dart: add getMyHoroscope() -> GET /my-horoscope
  - horoscope_repository + usecase: add getMyHoroscope / callMy methods
  - horoscope_bloc.dart: add FetchMyHoroscope event
  - horoscope_page.dart: complete redesign with period-aware titles,
    rasi symbol, sign browser panel, lucky factors cards

Flutter - home page:
  - _loadForecast: uses FetchMyHoroscope (server-side) when birth details
    present; falls back to FetchHoroscope(moonSign) then Mesha
  - BlocListener: reloads forecast when AuthAuthenticated re-emits
"@

$tmpFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmpFile, $msg, [System.Text.Encoding]::UTF8)
git commit -F $tmpFile
Remove-Item $tmpFile -Force

# Pull remote changes then push
git pull origin master --rebase
git push origin master
Write-Host "Done!" -ForegroundColor Green
