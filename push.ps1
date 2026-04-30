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
feat: profile completion, admin portal revamp, compile fixes

- Add ProfileCompletePage for admin-created users (DOB/TOB/Place form)
- Router redirects non-admin users without birth details to /complete-profile
- AuthBloc: UpdateBirthDetailsRequested event + handler
- SecureStorage: persist isAdmin flag; restore on app restart
- AuthAuthenticated.props includes dateOfBirth so router re-evaluates after save
- Admin portal: auto-login overlay, Has Birth Data stat, birth columns in table
- Admin portal: edit modal with birth detail fields (DOB/TOB/place/lat/lng/tz)
- Admin portal: filter by access level and birth data; sidebar footer shows email
- Fix DialogTheme vs DialogThemeData (Flutter 3.24) in register_page + profile_complete_page
- Fix const Text with non-const style in home_page
- Remove junk root files from repo
"@

git commit -m $msg
git push origin master
Write-Host "Done!" -ForegroundColor Green
