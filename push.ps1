# push.ps1 — commit and push all Jyotish AI changes
Set-Location "D:\Work\Claude\Jyotish"

# Remove stale lock if present
$lock = ".git\index.lock"
if (Test-Path $lock) { Remove-Item $lock -Force; Write-Host "Removed stale lock." }

git config user.email "atchayamganesh@gmail.com"
git config user.name  "Atchayam"

git add -A
git commit -m "feat: birth details in auth + personalized home & kundli pages

- Backend: user schema with birth details (dob, tob, place, lat, lng, tz, moon_sign)
- Backend: user repository update + new /profile endpoint
- Flutter: UserEntity, AuthModel, SecureStorage extended with birth fields
- Flutter: AuthRemoteDatasource, AuthRepositoryImpl, RegisterUseCase updated
- Flutter: AuthBloc persists and restores birth details from secure storage
- Flutter: Register page with DatePicker, TimePicker, Google Places autocomplete
- Flutter: Home page personalised with moon sign chip and birth place row
- Flutter: Kundli page auto-populates from user birth details and auto-fetches chart
- New: places_service.dart for Google Places integration
- New: user.py endpoint for profile fetch"

git push origin master
Write-Host "`nDone! Check above for any errors." -ForegroundColor Green
