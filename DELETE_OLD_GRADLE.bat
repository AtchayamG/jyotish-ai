@echo off
cd /d "D:\Work\Claude\Jyotish\flutter_app\android"
echo Deleting old Groovy gradle files...
if exist "settings.gradle" (del /f /q "settings.gradle" && echo [OK] Deleted settings.gradle) else echo [--] settings.gradle already gone
if exist "build.gradle" (del /f /q "build.gradle" && echo [OK] Deleted build.gradle) else echo [--] build.gradle already gone
if exist "app\build.gradle" (del /f /q "app\build.gradle" && echo [OK] Deleted app/build.gradle) else echo [--] app/build.gradle already gone
echo.
echo Checking KTS files...
if exist "settings.gradle.kts" (echo [OK] settings.gradle.kts exists) else echo [!!] MISSING settings.gradle.kts!
if exist "app\build.gradle.kts" (echo [OK] app/build.gradle.kts exists) else echo [!!] MISSING app/build.gradle.kts!
echo.
echo Done. Now run: flutter clean && flutter pub get && flutter run -d emulator-5554
pause
