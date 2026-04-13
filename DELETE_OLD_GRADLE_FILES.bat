@echo off
echo Deleting old Groovy gradle files...
cd /d D:\Work\Claude\Jyotish\flutter_app\android
if exist settings.gradle (
    del settings.gradle
    echo Deleted: settings.gradle
) else (
    echo Not found: settings.gradle (already deleted)
)
if exist build.gradle (
    del build.gradle
    echo Deleted: build.gradle
) else (
    echo Not found: build.gradle (already deleted)
)
if exist app\build.gradle (
    del app\build.gradle
    echo Deleted: app/build.gradle
) else (
    echo Not found: app/build.gradle (already deleted)
)
echo.
echo Done! Now run: flutter clean && flutter pub get && flutter run -d emulator-5554
pause
