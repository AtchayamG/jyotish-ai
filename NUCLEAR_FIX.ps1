Write-Host "=== Nuclear Android Fix ===" -ForegroundColor Red
$a = "D:\Work\Claude\Jyotish\flutter_app\android"

# Step 1: Delete EVERYTHING in android/app/src that is NOT our files
Write-Host "Cleaning android/app/src..." -ForegroundColor Yellow
$keep = @("main\AndroidManifest.xml","debug\AndroidManifest.xml","profile\AndroidManifest.xml","main\kotlin","main\res")

# Remove GeneratedPluginRegistrant.java if it exists (v1 leftover)
$gpj = Get-ChildItem "$a\app\src" -Recurse -Filter "GeneratedPluginRegistrant.java" -ErrorAction SilentlyContinue
foreach ($f in $gpj) { Remove-Item $f.FullName -Force; Write-Host "[DEL] $($f.FullName)" -ForegroundColor Green }

# Remove any .java files in kotlin folder (wrong language)
$java = Get-ChildItem "$a\app\src\main\kotlin" -Recurse -Filter "*.java" -ErrorAction SilentlyContinue
foreach ($f in $java) { Remove-Item $f.FullName -Force; Write-Host "[DEL] $($f.FullName)" -ForegroundColor Green }

# Remove nested flutter projects if they crept back
foreach ($d in @("android","ios","linux","macos","windows","web","lib","test")) {
    $p = Join-Path $a $d
    if (Test-Path $p) { Remove-Item $p -Recurse -Force; Write-Host "[DEL DIR] $d" -ForegroundColor Green }
}

# Remove leftover flutter-create files
foreach ($f in @("analysis_options.yaml","README.md",".metadata","pubspec.yaml","pubspec.lock","build.gradle","settings.gradle")) {
    $p = Join-Path $a $f
    if (Test-Path $p) { Remove-Item $p -Force; Write-Host "[DEL] $f" -ForegroundColor Green }
}

Write-Host ""
Write-Host "Cleanup done. Now copy the android files from the zip, then run:" -ForegroundColor Cyan
Write-Host "  cd D:\Work\Claude\Jyotish\flutter_app"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter run -d emulator-5554"
Read-Host "Enter to exit"
