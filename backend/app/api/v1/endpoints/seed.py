"""app/api/v1/endpoints/seed.py — DELETE after admin created"""
import uuid, logging
from datetime import datetime, timezone
from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel
from app.core.firebase import FirestoreCollection
from app.core.security import hash_password

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/seed", tags=["Seed"])

class SeedResp(BaseModel):
    status: str; user_id: str; email: str; message: str

@router.post("/admin", response_model=SeedResp)
async def seed_admin(x: str = Header(..., alias="X-Seed-Token")):
    if x != "JyotishSeed2025!": raise HTTPException(403, "Invalid token")
    try:
        db = FirestoreCollection("users")
        found = await db.get_where("email","==","atchayam@jyotishai.app",limit=1)
        if found:
            return SeedResp(status="already_exists", user_id=found[0].get("id","?"),
                email="atchayam@jyotishai.app", message="Exists. Password: Admin123")
        uid = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        await db.create(uid, {
            "id":uid,"email":"atchayam@jyotishai.app","full_name":"Atchayam Admin",
            "phone":"+919999999999","hashed_password":hash_password("Admin123"),
            "is_active":True,"is_premium":True,"is_admin":True,
            "created_at":now,"updated_at":now,
        })
        return SeedResp(status="created",user_id=uid,
            email="atchayam@jyotishai.app",
            message="Done! Login: atchayam@jyotishai.app / Admin123")
    except Exception as e:
        logger.error(f"Seed: {e}",exc_info=True)
        raise HTTPException(500, str(e))
