"""
scripts/seed_admin.py
Creates a super admin / all-access user directly in Firestore.
Run ONCE after deploying to Render.

Usage (local):    python scripts/seed_admin.py
Usage (on Render Shell tab): python scripts/seed_admin.py
Idempotent — safe to run multiple times.
"""
import asyncio, os, sys, uuid
from datetime import datetime, timezone

# ── Admin credentials — CHANGE THESE ─────────────────────────────────────────
ADMIN_EMAIL    = "atchayam@jyotishai.app"
ADMIN_PASSWORD = "JyotishAdmin@2025"
ADMIN_NAME     = "Atchayam Admin"
ADMIN_PHONE    = "+919999999999"
# ─────────────────────────────────────────────────────────────────────────────

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings
from app.core.firebase import init_firebase, FirestoreCollection
from app.core.security import hash_password


async def seed():
    print("\n" + "="*60)
    print("  Jyotish AI — Admin User Seeder")
    print("="*60 + "\n")

    init_firebase()
    print("✓ Firebase connected\n")

    users = FirestoreCollection("users")

    existing = await users.get_where("email", "==", ADMIN_EMAIL.lower(), limit=1)
    if existing:
        print(f"⚠  User already exists: {ADMIN_EMAIL}")
        print(f"   ID: {existing[0]['id']}")
        print("✓ Nothing to do — admin already seeded.\n")
        return

    user_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    data = {
        "id": user_id,
        "email": ADMIN_EMAIL.lower(),
        "full_name": ADMIN_NAME,
        "phone": ADMIN_PHONE,
        "hashed_password": hash_password(ADMIN_PASSWORD),
        "is_active": True,
        "is_premium": True,
        "is_admin": True,
        "created_at": now,
        "updated_at": now,
    }
    await users.create(user_id, data)

    print("✅  Admin user created!\n")
    print(f"   Email    : {ADMIN_EMAIL}")
    print(f"   Password : {ADMIN_PASSWORD}")
    print(f"   User ID  : {user_id}")
    print(f"   Premium  : True (full access)")
    print(f"   Admin    : True")
    print("\n" + "="*60)
    print("  ⚠  Save these credentials — password is hashed in DB")
    print("="*60 + "\n")


if __name__ == "__main__":
    asyncio.run(seed())
