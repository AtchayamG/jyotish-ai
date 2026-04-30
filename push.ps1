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
fix: seed set(merge=True) + promote endpoint; places proxy improvements

- seed.py: patch via Firestore set(merge=True), verify and return actual is_admin
- seed.py: add POST /api/v1/seed/promote?email=X to promote any user to admin
- places.py: param input->q, timezone soft fallback, better Google error messages
- places_service.dart: query param updated to match (q)
"@

git commit -m $msg

# Pull remote changes (e.g. CI APK commits) then push
git pull origin master --rebase
git push origin master
Write-Host "Done!" -ForegroundColor Green
