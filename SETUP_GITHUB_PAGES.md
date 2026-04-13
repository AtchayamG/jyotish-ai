# Enable GitHub Pages Auto-Deploy

## One-time setup (do this ONCE on GitHub website)

### Step 1 — Enable GitHub Pages
1. Go to your GitHub repo (AtchayamG/jyotish-ai)
2. Click **Settings** tab
3. Left sidebar → **Pages**
4. Under **Source** → select **"GitHub Actions"** (not "Deploy from a branch")
5. Click **Save**

### Step 2 — Set repo name in workflow
If your GitHub repo is named `jyotish-ai`, edit `.github/workflows/flutter_web_deploy.yml`:
```yaml
--base-href /jyotish-ai/
```
Replace `jyotish-ai` with your EXACT repo name.

If your default branch is `master` (not `main`), the workflow already handles both.

### Step 3 — Push the files
Add the workflow file to your **Flutter repo** (not the backend repo):
```
your-flutter-repo/
├── .github/
│   └── workflows/
│       └── flutter_web_deploy.yml   ← this file
├── flutter_app/
│   └── ...
```

After pushing, go to:
**GitHub repo → Actions tab** — you'll see the workflow running.

### Your live URL will be:
```
https://AtchayamG.github.io/jyotish-ai/
```

---

## How it works
Every time you push code to `main` or `master`:
1. GitHub spins up Ubuntu runner
2. Installs Flutter 3.24
3. Runs `flutter build web --release`
4. Deploys the `build/web/` folder to GitHub Pages
5. Your app is live in ~2-3 minutes

## CORS fix needed for GitHub Pages → Render
In Render dashboard, update `ALLOWED_ORIGINS`:
```
https://AtchayamG.github.io,http://localhost:3000
```
Replace `AtchayamG` with your GitHub username.
