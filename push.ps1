# push.ps1
Set-Location "D:\Work\Claude\Jyotish"

$lock = ".git\index.lock"
if (Test-Path $lock) { Remove-Item $lock -Force }

git config user.email "atchayamganesh@gmail.com"
git config user.name  "Atchayam"

git add -A
git commit -m "fix: CI build errors - shrinkResources, google-services stub, remove flutter create"
git push origin master
Write-Host "Done!" -ForegroundColor Green
