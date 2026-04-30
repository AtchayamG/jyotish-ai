"""app/api/v1/endpoints/seed.py — DELETE after admin created"""
import uuid, logging, asyncio
from datetime import datetime, timezone
from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel
from app.core.firebase import FirestoreCollection, get_db
from app.core.security import hash_password

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/seed", tags=["Seed"])

ADMIN_EMAIL    = "atchayam@jyotishai.app"
ADMIN_PASSWORD = "Admin123"
SEED_TOKEN     = "JyotishSeed2025!"


class SeedResp(BaseModel):
    status: str; user_id: str; email: str; message: str


async def _patch_firestore(uid: str, patch: dict) -> dict:
    """Write patch to Firestore using set(merge=True) and return the result."""
    fs = get_db()
    loop = asyncio.get_running_loop()
    patch["updated_at"] = datetime.now(timezone.utc).isoformat()
    await loop.run_in_executor(
        None, lambda: fs.collection("users").document(uid).set(patch, merge=True)
    )
    doc = await loop.run_in_executor(
        None, lambda: fs.collection("users").document(uid).get()
    )
    return doc.to_dict() or {}


@router.post("/admin", response_model=SeedResp)
async def seed_admin(x: str = Header(..., alias="X-Seed-Token")):
    """Create or promote the admin account. Protected by X-Seed-Token header."""
    if x != SEED_TOKEN:
        raise HTTPException(403, "Invalid token")
    try:
        db = FirestoreCollection("users")
        found = await db.get_where("email", "==", ADMIN_EMAIL, limit=1)

        if found:
            uid = found[0].get("id", "?")
            actual = await _patch_firestore(uid, {
                "is_admin": True,
                "is_premium": True,
                "is_active": True,
                "hashed_password": hash_password(ADMIN_PASSWORD),
            })
            is_admin_now = actual.get("is_admin")
            return SeedResp(
                status="updated", user_id=uid, email=ADMIN_EMAIL,
                message=f"Patched via set(merge=True). is_admin={is_admin_now}. "
                        f"Login: {ADMIN_EMAIL} / {ADMIN_PASSWORD}",
            )

        # Fresh create
        uid = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        await db.create(uid, {
            "id": uid, "email": ADMIN_EMAIL, "full_name": "Atchayam Admin",
            "phone": "+919999999999",
            "hashed_password": hash_password(ADMIN_PASSWORD),
            "is_active": True, "is_premium": True, "is_admin": True,
            "created_at": now, "updated_at": now,
        })
        return SeedResp(
            status="created", user_id=uid, email=ADMIN_EMAIL,
            message=f"Created. Login: {ADMIN_EMAIL} / {ADMIN_PASSWORD}",
        )

    except Exception as e:
        logger.error("Seed error: %s", e, exc_info=True)
        raise HTTPException(500, str(e))


@router.post("/promote", response_model=SeedResp)
async def promote_to_admin(
    email: str,
    x: str = Header(..., alias="X-Seed-Token"),
):
    """Promote ANY existing user to admin by email. Emergency fallback."""
    if x != SEED_TOKEN:
        raise HTTPException(403, "Invalid token")
    try:
        db = FirestoreCollection("users")
        found = await db.get_where("email", "==", email.lower(), limit=1)
        if not found:
            raise HTTPException(404, f"User not found: {email}")
        uid = found[0].get("id", "?")
        actual = await _patch_firestore(uid, {"is_admin": True, "is_active": True})
        return SeedResp(
            status="promoted", user_id=uid, email=email,
            message=f"is_admin={actual.get('is_admin')}. User promoted to admin.",
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Promote error: %s", e, exc_info=True)
        raise HTTPException(500, str(e))
