# push.ps1 - commit + push script
# Usage: powershell -ExecutionPolicy Bypass -File .\push.ps1

Set-Location "D:\Work\Claude\Jyotish"

# Remove stale git lock if present
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
feat: basic tier + free trial + favicon + Places in AddProfile

Monetization - Free tier 3-day trial:
  - user_entity.dart: isTrialExpired getter (DateTime.parse + 3-day window)
  - app_router.dart: redirect to /pricing for expired free users
  - pricing_page.dart: PopScope(canPop: false) when trial expired,
    trial-expired red banner, back button hidden for expired users

Monetization - Basic tier (Rs. 99/month):
  - backend user_schema.py: UserTier.basic = basic added to enum
  - user_entity.dart: UserTier.basic with 0 extra profiles, full features
  - pricing_page.dart: Basic plan card between Free and Premium

Registration timestamp for trial:
  - auth_model.dart: UserModel.registeredAt parses created_at from JSON
  - secure_storage.dart: _kRegisteredAt key, saveUser registeredAt param,
    getRegisteredAt() method
  - auth_bloc.dart: save + load registeredAt on login/register/_onCheck,
    thread through all UserEntity constructions

Admin portal:
  - admin/index.html: all tier dropdowns (add-user, edit-user, filter)
    now include basic and max options

Web favicon:
  - web/index.html: SVG favicon link, updated title to Jyotish AI,
    improved meta description and apple-mobile tags
  - web/favicon.svg: new Jyotish AI 8-pointed star icon (gold on dark)

Add Profile - Google Places autocomplete:
  - add_profile_page.dart: full PlacesService integration matching
    register_page pattern (debounce 450ms, dropdown, coord pill,
    lat/lng/tz captured for astro calculations)
"@

$tmpFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmpFile, $msg, [System.Text.Encoding]::UTF8)
git commit -F $tmpFile
Remove-Item $tmpFile -Force

# Sync with remote then push
git fetch origin master

git rebase origin/master
if ($LASTEXITCODE -ne 0) {
    Write-Host "Rebase conflict - aborting, using force-with-lease" -ForegroundColor Yellow
    git rebase --abort
    git push origin master --force-with-lease
} else {
    git push origin master
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Push rejected - retrying with force-with-lease" -ForegroundColor Yellow
        git push origin master --force-with-lease
    }
}

Write-Host "Done!" -ForegroundColor Green
