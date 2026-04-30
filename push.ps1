# push.ps1 — commit and push CI/CD changes
Set-Location "D:\Work\Claude\Jyotish"

$lock = ".git\index.lock"
if (Test-Path $lock) { Remove-Item $lock -Force; Write-Host "Removed stale lock." }

git config user.email "atchayamganesh@gmail.com"
git config user.name  "Atchayam"

git add -A

$msg = @"
ci: unified GitHub Pages + Fastlane APK automation

Flutter web served at root, admin portal at /admin/ subfolder.
APK built via Fastlane on every push, stored in releases/ folder.
"@

git commit -m $msg
git push origin master
Write-Host "`nDone!" -ForegroundColor Green
