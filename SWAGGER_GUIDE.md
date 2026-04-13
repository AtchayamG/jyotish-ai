# How to Use Swagger to Test Jyotish AI API

## Open Swagger
URL: https://jyotish-ai-4xw2.onrender.com/docs

---

## Step 1 — Create Admin User (one time only)

1. In Swagger, find: **POST /api/v1/seed/admin**
2. Click **"Try it out"**
3. Click **"Execute"** — do NOT add any body
4. In the "Parameters" section above Execute, find **X-Seed-Token**
   — Type: `JyotishSeed2025!`
5. Click Execute
6. Expected response:
   ```json
   { "status": "created", "email": "atchayam@jyotishai.app" }
   ```

---

## Step 2 — Login and Get JWT Token

1. Find: **POST /api/v1/auth/login**
2. Click **"Try it out"**
3. In the Request Body, paste:
   ```json
   {
     "email": "atchayam@jyotishai.app",
     "password": "JyotishAdmin@2025"
   }
   ```
4. Click **Execute**
5. In the response, copy the `access_token` value (starts with `eyJ...`)

---

## Step 3 — Authorise Swagger to Use Your Token

1. Click the **"Authorize"** button at the TOP RIGHT of the Swagger page (🔓 lock icon)
2. In the dialog, type: `Bearer eyJxxxxxx...` (paste your full access_token)
3. Click **Authorize** → then **Close**
4. Now ALL requests will include your JWT automatically

---

## Step 4 — Create a New User via Admin API

1. Find: **POST /api/v1/admin/users**
2. Click **"Try it out"**
3. Request body:
   ```json
   {
     "email": "testuser@example.com",
     "full_name": "Test User",
     "password": "Password123",
     "is_premium": false,
     "is_admin": false,
     "is_active": true
   }
   ```
4. Click **Execute** — returns the created user with their ID

---

## Step 5 — View All Users

1. Find: **GET /api/v1/admin/users**
2. Click **"Try it out"** → **Execute**
3. Returns array of all users (without hashed_password)

---

## Step 6 — Test Astrology APIs

### Daily Horoscope (no auth needed)
1. **GET /api/v1/astrology/horoscope/{sign}**
2. Set sign = `Mesha`
3. Execute — returns today's horoscope

### AI Chat
1. **POST /api/v1/astrology/chat**
2. Body:
   ```json
   {
     "message": "What does my current dasha indicate?",
     "history": [],
     "language": "en"
   }
   ```

### Kundli (requires auth)
1. **POST /api/v1/astrology/kundli**
2. Body:
   ```json
   {
     "name": "Atchayam",
     "year": 1990, "month": 4, "day": 12,
     "hour": 6, "minute": 30,
     "latitude": 13.0827, "longitude": 80.2707,
     "timezone": 5.5, "ayanamsa": "lahiri"
   }
   ```

---

## Step 7 — Check All Available APIs

The Swagger page shows all routes grouped by tag:
- **Auth** — register, login, refresh, google auth, fcm-token
- **Astrology** — kundli, horoscope, match, muhurtham, chat
- **Admin** — users CRUD, send notifications, stats
- **Seed** — one-time admin creator (delete after use)
- **Health** — GET /health (always returns 200 if server is running)

---

## Tips
- If you get 401: re-authorise with a fresh token (tokens expire in 60 minutes)
- If you get 500: check Render logs for the exact Python traceback
- The `/health` endpoint has no auth — good for testing connectivity
