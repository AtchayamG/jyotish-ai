# Push Fresh Clean Repo

## Step 1 — Open CMD in D:\Work\Claude\Jyotish

```cmd
cd D:\Work\Claude\Jyotish
```

## Step 2 — Reset git history completely
```cmd
rmdir /s /q .git
git init
git remote add origin https://github.com/AtchayamG/jyotish-ai.git
```

## Step 3 — Copy the clean files from this zip
Extract jyotish_clean_project.zip into D:\Work\Claude\Jyotish\
(overwrite all existing files)

## Step 4 — Stage and push
```cmd
git add .
git commit -m "clean: fresh start"
git push -f origin master
```

## Step 5 — Run the app
```cmd
cd flutter_app
flutter clean
flutter pub get
flutter run -d emulator-5554
flutter run -d chrome
```

## Step 6 — Create admin user
Wait 3 min for Render to redeploy, then:
POST https://jyotish-ai-4xw2.onrender.com/api/v1/seed/admin
Header: X-Seed-Token: JyotishSeed2025!

Login: atchayam@jyotishai.app / Admin123
