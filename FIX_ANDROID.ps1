Write-Host "=== Jyotish AI Android Fix ===" -ForegroundColor Cyan
$androidDir = "D:\Work\Claude\Jyotish\flutter_app\android"
Set-Location $androidDir
Write-Host "Working in: $androidDir"

$files = @("settings.gradle", "build.gradle", "app\build.gradle")
foreach ($f in $files) {
    if (Test-Path $f) {
        Remove-Item $f -Force
        Write-Host "[DELETED] $f" -ForegroundColor Green
    } else {
        Write-Host "[SKIP] $f not found" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Checking KTS files..." -ForegroundColor Cyan
if (Test-Path "settings.gradle.kts") { Write-Host "[OK] settings.gradle.kts" -ForegroundColor Green }
else { Write-Host "[MISSING] settings.gradle.kts - copy from zip!" -ForegroundColor Red }
if (Test-Path "app\build.gradle.kts") { Write-Host "[OK] app/build.gradle.kts" -ForegroundColor Green }
else { Write-Host "[MISSING] app/build.gradle.kts - copy from zip!" -ForegroundColor Red }

Write-Host ""
Write-Host "Done! Now run in flutter_app/:" -ForegroundColor Yellow
Write-Host "  flutter clean && flutter pub get && flutter run -d emulator-5554"
Read-Host "Press Enter to exit"
