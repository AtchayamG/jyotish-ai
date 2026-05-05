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
fix: admin tier + responsive shell + AI chat overhaul

Admin tier fix:
  - user_schema.py: @model_validator on UserPublic reconciles is_admin/is_premium
    with user_tier on every response - no DB migration needed
  - auth_bloc.dart: _onCheck derives tier from isAdmin flag in SecureStorage
  - Admin users see correct unlimited tier without re-login

Responsive web shell:
  - shell_page.dart: LayoutBuilder + 720px breakpoint (not kIsWeb alone)
  - Mobile browsers (<720px): bottom nav bar, same as native app
  - Desktop browsers (>=720px): sidebar + 860px max-width content area

AI Chat overhaul:
  - Intent detection: 17 categories (career, marriage, dasha, lagna, etc.)
  - Focused context: strips planet list for simple intents to reduce tokens
  - Dynamic system prompt per intent with specific instructions
  - Intent-aware max_tokens (300-800)
  - Firestore chat history: load last 10, save each exchange per user
  - /chat endpoint now authenticated - birth from user profile, not client
  - Removed userContext from all Flutter layers (datasource, repo, bloc, page)

Push script:
  - fetch + rebase + push with auto force-with-lease fallback
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
