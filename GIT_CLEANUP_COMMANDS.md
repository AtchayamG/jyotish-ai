# Git Cleanup — Run These Commands

## Step 1: Remove the nested Flutter project from tracking
(This is the flutter_app/android/android/ folder that got committed by mistake)

```bash
cd D:\Work\Claude\Jyotish

git rm -r --cached flutter_app/android/android/
git rm -r --cached flutter_app/android/ios/
git rm -r --cached flutter_app/android/linux/
git rm -r --cached flutter_app/android/macos/
git rm -r --cached flutter_app/android/windows/
git rm -r --cached flutter_app/android/web/
git rm -r --cached flutter_app/android/lib/
git rm -r --cached flutter_app/android/test/
git rm -r --cached flutter_app/android/pubspec.yaml
git rm -r --cached flutter_app/android/pubspec.lock
git rm -r --cached flutter_app/android/.metadata
git rm -r --cached flutter_app/android/.gradle/
git rm -r --cached flutter_app/android/local.properties
git rm --cached WHAT_TO_DO_NEXT.md
```

## Step 2: Copy the new .gitignore to repo root
Copy gitignore_root.txt → D:\Work\Claude\Jyotish\.gitignore (rename it)

## Step 3: Fix the blocked push (OpenAI key)
The previous commit had the key. Run:
```bash
git reset HEAD~1 --soft
```
Then recommit WITHOUT WHAT_TO_DO_NEXT.md:
```bash
git add backend/ flutter_app/lib/ flutter_app/android/ flutter_app/pubspec.yaml .github/
git commit -m "fix: firebase + android + admin console"
git push
```

## Step 4: Delete these folders from local disk too
In Windows Explorer, delete these physical folders:
- D:\Work\Claude\Jyotish\flutter_app\android\android\
- D:\Work\Claude\Jyotish\flutter_app\android\ios\
- D:\Work\Claude\Jyotish\flutter_app\android\linux\
- D:\Work\Claude\Jyotish\flutter_app\android\macos\
- D:\Work\Claude\Jyotish\flutter_app\android\windows\
- D:\Work\Claude\Jyotish\flutter_app\android\web\
- D:\Work\Claude\Jyotish\flutter_app\android\lib\
- D:\Work\Claude\Jyotish\flutter_app\android\test\

## Step 5: Verify what you are about to push
```bash
git status
git diff --name-only --cached
```
Make sure no .env files or google-services.json appear in the list.
