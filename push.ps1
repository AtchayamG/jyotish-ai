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
feat: fix Prokerala 500, remove admin tab, splash 3s, AI chat user context

Backend:
- astrology_repository.py: catch ExternalAPIError in _prokerala_get + _get_token
  so Prokerala failures fall back to mock data instead of 500
- ai_chat_service.py: tighten system prompt — AI must respond from user chart only

Flutter:
- shell_page.dart + app_router.dart: remove admin tab & route (standalone portal)
- splash_page.dart: enforce 3s minimum display; pulsing rings + animated dots
- ai_chat/*: thread user birth details through ChatBloc → usecase → datasource
  so every AI message includes the user's Lagna/Rasi/Nakshatra/Dasha context
- ai_chat_page.dart: personalised welcome (name, DOB chip, place, moon sign)
"@

git commit -m $msg

# Pull remote changes (e.g. CI APK commits) then push
git pull origin master --rebase
git push origin master
Write-Host "Done!" -ForegroundColor Green
