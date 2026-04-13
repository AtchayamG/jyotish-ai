# Render Environment Variable Update
## Add these in Render Dashboard → your service → Environment

### Step 1 — Open Render Dashboard
1. Go to https://render.com → your service `jyotish-ai-4xw2`
2. Click **Environment** tab
3. Add/update these variables:

| Key | Value |
|-----|-------|
| `PROKERALA_CLIENT_ID` | `e87c610a-a146-43c9-a8f5-274fabdd3b1c` |
| `PROKERALA_CLIENT_SECRET` | `ag1OUvgqM1S2Uz2A7DKOGeu8AEXoXs5P35IMbK6c` |
| `OPENAI_API_KEY` | `your_openai_api_key_here` |
| `OPENAI_MODEL` | `gpt-4o-mini` |

### Step 2 — Update Prokerala Authorized Origins
Go to: https://api.prokerala.com/account/client/e87c610a-a146-43c9-a8f5-274fabdd3b1c

In **Authorized JavaScript Origins**, add:
```
https://jyotish-ai-4xw2.onrender.com
```
Click Update.

### Step 3 — Get OpenAI API Key (if you don't have one)
1. Go to https://platform.openai.com/api-keys
2. Click **Create new secret key**
3. Name: `JyotishAI`
4. Copy the key (starts with `sk-...`)
5. Paste it as `OPENAI_API_KEY` in Render

### Step 4 — Save & Redeploy
After adding all env vars → click **Save Changes**
Render will automatically redeploy.

### Cost estimate for OpenAI gpt-4o-mini
- ~$0.15 per 1M input tokens
- ~$0.60 per 1M output tokens
- A typical chat message costs ~$0.0003 (less than 1 paisa)
- 1000 messages/day ≈ $0.30/day

### Verify it's working
After redeploy, test at:
https://jyotish-ai-4xw2.onrender.com/docs
POST /api/v1/astrology/chat
Body: {"message": "Tell me today's forecast for Mesha"}
