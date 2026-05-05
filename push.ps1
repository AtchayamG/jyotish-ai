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
fix: build errors - missing AuthModel import + jcenter for flutter_secure_storage

Dart compile fix:
  - auth_repository_impl.dart: added missing import for auth_model.dart
  - _authModelToEntity(AuthModel m) now resolves correctly on all platforms

Android Gradle fix:
  - build.gradle.kts: added jcenter() to allprojects.repositories
  - settings.gradle.kts: added jcenter() to pluginManagement.repositories
  - Resolves flutter_secure_storage 9.2.2 dependency failures in CI:
    kotlin-stdlib-jdk8:1.9.20, commons-io:2.13.0, asm:9.6 now resolvable
"@

$tmpFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tmpFile, $msg, [System.Text.Encoding]::UTF8)
git commit -F $tmpFile
Remove-Item $tmpFile -Force

# Pull remote changes then push
git pull origin master --rebase
git push origin master
Write-Host "Done!" -ForegroundColor Green
