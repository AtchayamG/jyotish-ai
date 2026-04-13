# Jyotish AI — Complete Render Deployment Guide
## Step-by-step: Firebase → GitHub → Render → Flutter

---

## OVERVIEW

```
Your PC  →  GitHub repo  →  Render (auto-deploy)  →  Flutter app
                                    ↑
                               Firebase (DB)
```

**Time required:** ~30 minutes  
**Cost:** Free tier (Render free + Firebase Spark free)

---

## PART 1 — FIREBASE SETUP (Database)

### Step 1.1 — Create Firebase Project

1. Open **https://console.firebase.google.com**
2. Click **"Add project"**
3. Project name: `jyotish-ai`
4. **Disable** Google Analytics (not needed)
5. Click **"Create project"** → wait ~30 seconds

### Step 1.2 — Enable Firestore Database

1. In left sidebar → **"Build"** → **"Firestore Database"**
2. Click **"Create database"**
3. Select **"Start in production mode"**
4. Location: **`asia-south1`** (Mumbai — closest to Chennai)
5. Click **"Enable"**

### Step 1.3 — Set Firestore Security Rules

1. Click the **"Rules"** tab in Firestore
2. Replace all content with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only server (Admin SDK) can read/write — Flutter uses our API, not Firebase directly
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

3. Click **"Publish"**

> ✅ This locks the DB to server-side only. Flutter talks to our FastAPI, not Firebase directly.

### Step 1.4 — Create Service Account (API credentials)

1. Top-left → Click the **gear icon ⚙** → **"Project settings"**
2. Click the **"Service accounts"** tab
3. Make sure **"Firebase Admin SDK"** is selected
4. Click **"Generate new private key"**
5. Confirm → A file named `jyotish-ai-firebase-adminsdk-xxxxx.json` downloads
6. **KEEP THIS FILE SAFE** — treat it like a password

### Step 1.5 — Copy Firebase credentials for Render

1. Open the downloaded `.json` file in any text editor (Notepad, VS Code)
2. Select **ALL** content → Copy (Ctrl+A, Ctrl+C)
3. Save this copied text — you'll paste it into Render in Part 3

The JSON looks like this (yours will have real values):
```json
{
  "type": "service_account",
  "project_id": "jyotish-ai",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN RSA PRIVATE KEY-----\n...",
  "client_email": "firebase-adminsdk-xxx@jyotish-ai.iam.gserviceaccount.com",
  ...
}
```

---

## PART 2 — GITHUB SETUP (Code hosting)

### Step 2.1 — Create GitHub account (if you don't have one)

1. Go to **https://github.com** → Sign up (free)

### Step 2.2 — Create a new repository

1. Click **"+"** (top right) → **"New repository"**
2. Repository name: `jyotish-ai-backend`
3. Set to **Private**
4. Do NOT initialise with README
5. Click **"Create repository"**

### Step 2.3 — Upload the backend code

**Option A — Using GitHub website (no Git needed):**

1. Extract `jyotish_ai_part1_backend.zip` on your PC
2. Open the `backend/` folder
3. On the GitHub repo page, click **"uploading an existing file"**
4. Drag ALL files and folders from `backend/` into the upload area
5. Important: Also upload the updated files from this zip:
   - `app/core/firebase.py` (replace existing)
   - `render.yaml` (replace existing)
   - `scripts/seed_admin.py` (new file)
6. Scroll down → commit message: `Initial backend deployment`
7. Click **"Commit changes"**

**Option B — Using Git (faster):**

```bash
# On your PC, open terminal/cmd in the backend/ folder
git init
git add .
git commit -m "Initial backend deployment"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/jyotish-ai-backend.git
git push -u origin main
```

### Step 2.4 — Verify upload

Your GitHub repo should look like this:
```
jyotish-ai-backend/
├── app/
│   ├── api/
│   ├── core/
│   ├── repositories/
│   ├── schemas/
│   ├── services/
│   └── __init__.py
├── scripts/
│   └── seed_admin.py
├── tests/
├── main.py
├── render.yaml
└── requirements.txt
```

---

## PART 3 — RENDER SETUP (Hosting)

### Step 3.1 — Create Render account

1. Go to **https://render.com**
2. Click **"Get Started"** → Sign up with GitHub (easiest)
3. Authorise Render to access your GitHub

### Step 3.2 — Create new Web Service

1. Dashboard → click **"New +"** → **"Web Service"**
2. Click **"Connect a repository"**
3. Find `jyotish-ai-backend` → click **"Connect"**

### Step 3.3 — Configure the service

Fill in these settings:

| Field | Value |
|-------|-------|
| **Name** | `jyotish-ai-backend` |
| **Region** | Singapore (closest to India) |
| **Branch** | `main` |
| **Runtime** | `Python 3` |
| **Build Command** | `pip install -r requirements.txt` |
| **Start Command** | `uvicorn main:app --host 0.0.0.0 --port $PORT --workers 2` |
| **Plan** | Free (or Starter $7/mo for always-on) |

### Step 3.4 — Set Environment Variables

Scroll down to **"Environment Variables"** section.  
Click **"Add Environment Variable"** for each row below:

| Key | Value |
|-----|-------|
| `APP_NAME` | `JyotishAI` |
| `APP_ENV` | `production` |
| `DEBUG` | `false` |
| `SECRET_KEY` | Click **"Generate"** button → auto-fills a secure key |
| `ALGORITHM` | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `60` |
| `REFRESH_TOKEN_EXPIRE_DAYS` | `30` |
| `ALLOWED_ORIGINS` | `*` |
| `FIREBASE_PROJECT_ID` | `jyotish-ai` (your project ID) |
| `FIREBASE_CREDENTIALS_JSON_CONTENT` | *Paste the entire JSON you copied in Step 1.5* |
| `PROKERALA_CLIENT_ID` | Leave blank for now (mock data works) |
| `PROKERALA_CLIENT_SECRET` | Leave blank for now |
| `OPENAI_API_KEY` | Leave blank (rule-based AI works without it) |
| `RAZORPAY_KEY_ID` | Leave blank for now |
| `RAZORPAY_KEY_SECRET` | Leave blank for now |

> ⚠️ **IMPORTANT for FIREBASE_CREDENTIALS_JSON_CONTENT:**
> - Click the value field
> - Paste the ENTIRE JSON content from Step 1.5 (the whole file, including the curly braces)
> - It should start with `{` and end with `}`

### Step 3.5 — Deploy

1. Click **"Create Web Service"** at the bottom
2. Render will start building — watch the **"Logs"** tab
3. Build takes ~3-5 minutes
4. When you see: `✓ Application startup complete.` — you're live!

### Step 3.6 — Get your backend URL

After deployment, Render shows your URL at the top:
```
https://jyotish-ai-backend.onrender.com
```

**Test it immediately:**
1. Open your browser → go to:
   ```
   https://jyotish-ai-backend.onrender.com/health
   ```
2. You should see:
   ```json
   {"status": "ok", "app": "JyotishAI", "version": "1.0.0"}
   ```
3. Open the API docs:
   ```
   https://jyotish-ai-backend.onrender.com/docs
   ```

---

## PART 4 — CREATE YOUR ADMIN USER

### Step 4.1 — Open Render Shell

1. In Render dashboard → click your service `jyotish-ai-backend`
2. Click the **"Shell"** tab (in the top menu)
3. A terminal opens inside your running server

### Step 4.2 — Run the seed script

Type this in the Shell:

```bash
python scripts/seed_admin.py
```

You'll see:
```
============================================================
  Jyotish AI — Admin User Seeder
============================================================

✓ Firebase connected

✅  Admin user created!

   Email    : atchayam@jyotishai.app
   Password : JyotishAdmin@2025
   User ID  : 550e8400-e29b-41d4-a716-446655440000
   Premium  : True (full access)
   Admin    : True

============================================================
  ⚠  Save these credentials — password is hashed in DB
============================================================
```

### Step 4.3 — Test login via API docs

1. Go to `https://jyotish-ai-backend.onrender.com/docs`
2. Click **POST /api/v1/auth/login** → **"Try it out"**
3. Enter:
```json
{
  "email": "atchayam@jyotishai.app",
  "password": "JyotishAdmin@2025"
}
```
4. Click **Execute**
5. Copy the `access_token` from the response
6. Click **"Authorize"** (lock icon, top right of docs page)
7. Paste the token → now all endpoints are unlocked

---

## PART 5 — CONNECT FLUTTER TO RENDER

### Step 5.1 — Update the base URL

Open `flutter_app/lib/core/api/api_constants.dart`:

```dart
// Change this line:
static const String baseUrlProd = 'https://jyotish-ai-backend.onrender.com';
```

Replace `jyotish-ai-backend` with your actual Render service name.

### Step 5.2 — Switch Flutter to production mode

In `flutter_app/lib/main.dart`, add this before `setupLocator()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  ApiConstants.setProduction(); // ← ADD THIS LINE
  
  await setupLocator();
  runApp(const JyotishApp());
}
```

### Step 5.3 — Build and run

```bash
cd flutter_app
flutter pub get
flutter run    # for debug testing
# or
flutter build apk --release    # for Android APK
```

---

## PART 6 — IMPORTANT NOTES

### Free Tier Limitations

| Issue | Cause | Fix |
|-------|-------|-----|
| First request takes 30-60s | Free tier "sleeps" after 15 min inactivity | Upgrade to Starter ($7/mo) |
| 750 hours/month limit | Render free tier | Fine for testing, upgrade for production |

### Keep it awake (free tier workaround)

Add a cron job that pings your health endpoint every 10 minutes:
- Use **https://cron-job.org** (free)
- URL: `https://jyotish-ai-backend.onrender.com/health`
- Interval: Every 10 minutes

### Auto-deploy on code changes

Every `git push` to your `main` branch triggers an automatic re-deploy.
No manual steps needed.

### Monitor logs

Render Dashboard → your service → **"Logs"** tab  
Shows real-time logs from FastAPI.

---

## PART 7 — FULL API REFERENCE

Base URL: `https://jyotish-ai-backend.onrender.com`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/v1/auth/register` | No | Create new account |
| POST | `/api/v1/auth/login` | No | Login → get tokens |
| POST | `/api/v1/auth/refresh` | No | Refresh access token |
| POST | `/api/v1/astrology/kundli` | Yes | Generate birth chart |
| POST | `/api/v1/astrology/horoscope` | No | Get horoscope |
| GET  | `/api/v1/astrology/horoscope/{sign}` | No | Quick horoscope by sign |
| POST | `/api/v1/astrology/match` | Yes | Guna Milan compatibility |
| POST | `/api/v1/astrology/muhurtham` | Yes | Find auspicious times |
| POST | `/api/v1/astrology/chat` | No | AI astrologer chat |
| GET  | `/health` | No | Health check |
| GET  | `/docs` | No | Interactive API docs |

---

## ADMIN CREDENTIALS (Your all-access account)

```
Email    : atchayam@jyotishai.app
Password : JyotishAdmin@2025
Access   : Premium + Admin (all endpoints unlocked)
```

> Change the password after first login by updating the script and re-running,
> or directly in Firebase console → Firestore → users collection → your document.

---

## TROUBLESHOOTING

**Build fails:**
→ Check Logs tab → usually a missing package
→ Make sure `requirements.txt` is in the root (not inside `app/`)

**Firebase error on startup:**
→ Double-check `FIREBASE_CREDENTIALS_JSON_CONTENT` — must be the full JSON, no truncation
→ Make sure `FIREBASE_PROJECT_ID` matches your actual Firebase project ID

**401 Unauthorized:**
→ Token expired — use `/api/v1/auth/refresh` with your refresh token

**CORS error from Flutter:**
→ Set `ALLOWED_ORIGINS` to `*` in Render env vars

**Seed script: "Firebase not initialised":**
→ Make sure `FIREBASE_CREDENTIALS_JSON_CONTENT` is set in Render env vars before running
