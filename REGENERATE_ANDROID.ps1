Write-Host "=== Regenerating Android folder from scratch ===" -ForegroundColor Cyan
$proj = "D:\Work\Claude\Jyotish\flutter_app"
$android = "$proj\android"

# Step 1: Backup local.properties (has SDK path)
$lp = "$android\local.properties"
$lpContent = ""
if (Test-Path $lp) {
    $lpContent = Get-Content $lp -Raw
    Write-Host "[BACKED UP] local.properties" -ForegroundColor Green
}

# Step 2: Delete entire android folder
Write-Host "Deleting android folder..." -ForegroundColor Yellow
Remove-Item $android -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "[DELETED] android/" -ForegroundColor Green

# Step 3: Regenerate android folder using flutter create
Write-Host "Regenerating android folder with flutter create..." -ForegroundColor Yellow
Set-Location $proj
flutter create --platforms android .
Write-Host "[CREATED] android/ regenerated" -ForegroundColor Green

# Step 4: Restore local.properties
if ($lpContent -ne "") {
    Set-Content -Path $lp -Value $lpContent
    Write-Host "[RESTORED] local.properties" -ForegroundColor Green
}

# Step 5: Fix the AndroidManifest to add flutterEmbedding=2
$manifest = "$android\app\src\main\AndroidManifest.xml"
$content = Get-Content $manifest -Raw
if ($content -notmatch "flutterEmbedding") {
    $content = $content -replace "(</application>)", '        <meta-data android:name="flutterEmbedding" android:value="2"/>'+"\n    </application>"
    Set-Content $manifest $content
    Write-Host "[FIXED] Added flutterEmbedding=2 to manifest" -ForegroundColor Green
} else {
    Write-Host "[OK] flutterEmbedding already present" -ForegroundColor Green
}

Write-Host "" 
Write-Host "Done! Now run:" -ForegroundColor Cyan
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter run -d emulator-5554"
Read-Host "Press Enter to exit"
