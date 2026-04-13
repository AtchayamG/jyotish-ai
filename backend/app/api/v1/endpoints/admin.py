"""
app/api/v1/endpoints/admin.py
Admin API: user CRUD, push notifications, DB stats.
All routes require is_admin=True.
"""
import uuid, logging
from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, EmailStr
from app.core.dependencies import CurrentUser
from app.core.firebase import FirestoreCollection
from app.core.security import hash_password
from app.schemas.user_schema import UserInDB

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/admin", tags=["Admin"])

# ── Admin guard ───────────────────────────────────────────────────────────────
async def require_admin(user: CurrentUser) -> UserInDB:
    if not getattr(user, "is_admin", False):
        raise HTTPException(status_code=403, detail="Admin access required")
    return user

# ── Schemas ───────────────────────────────────────────────────────────────────
class AdminUserCreate(BaseModel):
    email: EmailStr; full_name: str; password: str
    phone: Optional[str] = None
    is_premium: bool = False; is_admin: bool = False; is_active: bool = True

class AdminUserUpdate(BaseModel):
    email: Optional[EmailStr] = None; full_name: Optional[str] = None
    phone: Optional[str] = None; password: Optional[str] = None
    is_premium: Optional[bool] = None; is_admin: Optional[bool] = None
    is_active: Optional[bool] = None

class NotifRequest(BaseModel):
    title: str; body: str
    target: str = "all"   # all | premium | free | topic
    topic: Optional[str] = None
    deep_link: Optional[str] = None
    image_url: Optional[str] = None

class NotifResponse(BaseModel):
    sent_count: int; status: str; message: str

# ── Users ─────────────────────────────────────────────────────────────────────
@router.get("/users", response_model=List[dict])
async def list_users(_: UserInDB = Depends(require_admin)):
    users = await FirestoreCollection("users").list_all(500)
    # Strip hashed_password from response
    for u in users:
        u.pop("hashed_password", None)
    return users

@router.post("/users", response_model=dict, status_code=201)
async def create_user(payload: AdminUserCreate, _: UserInDB = Depends(require_admin)):
    users = FirestoreCollection("users")
    existing = await users.get_where("email", "==", payload.email.lower(), limit=1)
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")
    uid = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    data = {
        "id": uid, "email": payload.email.lower(), "full_name": payload.full_name,
        "phone": payload.phone, "hashed_password": hash_password(payload.password),
        "is_active": payload.is_active, "is_premium": payload.is_premium,
        "is_admin": payload.is_admin, "created_at": now, "updated_at": now,
    }
    await users.create(uid, data)
    data.pop("hashed_password", None)
    return data

@router.put("/users/{user_id}", response_model=dict)
async def update_user(user_id: str, payload: AdminUserUpdate, _: UserInDB = Depends(require_admin)):
    users = FirestoreCollection("users")
    existing = await users.get_by_id(user_id)
    if not existing:
        raise HTTPException(status_code=404, detail="User not found")
    update = {}
    if payload.email is not None:    update["email"] = payload.email.lower()
    if payload.full_name is not None: update["full_name"] = payload.full_name
    if payload.phone is not None:    update["phone"] = payload.phone
    if payload.password is not None: update["hashed_password"] = hash_password(payload.password)
    if payload.is_premium is not None: update["is_premium"] = payload.is_premium
    if payload.is_admin is not None:   update["is_admin"] = payload.is_admin
    if payload.is_active is not None:  update["is_active"] = payload.is_active
    if update:
        await users.update(user_id, update)
    result = await users.get_by_id(user_id)
    result.pop("hashed_password", None)
    return result

@router.delete("/users/{user_id}", status_code=204)
async def delete_user(user_id: str, _: UserInDB = Depends(require_admin)):
    users = FirestoreCollection("users")
    existing = await users.get_by_id(user_id)
    if not existing:
        raise HTTPException(status_code=404, detail="User not found")
    await users.delete(user_id)

# ── Notifications ─────────────────────────────────────────────────────────────
@router.post("/notifications/send", response_model=NotifResponse)
async def send_notification(req: NotifRequest, _: UserInDB = Depends(require_admin)):
    """Send Firebase Cloud Messaging push notification."""
    try:
        import firebase_admin.messaging as messaging
        sent_count = 0

        if req.target == "topic":
            # Send to topic
            topic = req.topic or "all_users"
            msg = messaging.Message(
                notification=messaging.Notification(title=req.title, body=req.body),
                topic=topic,
                data={"deep_link": req.deep_link or "", "image_url": req.image_url or ""},
            )
            messaging.send(msg)
            sent_count = -1  # Unknown count for topic
            status_str = "sent_to_topic"
        else:
            # Get FCM tokens from users
            users = await FirestoreCollection("users").list_all(500)
            filtered = []
            for u in users:
                if req.target == "premium" and not u.get("is_premium"): continue
                if req.target == "free" and u.get("is_premium"): continue
                token = u.get("fcm_token")
                if token: filtered.append(token)

            if not filtered:
                return NotifResponse(sent_count=0, status="no_tokens",
                    message="No FCM tokens found. Users must open the app first.")

            # Batch send (FCM limit: 500 per batch)
            msgs = [
                messaging.Message(
                    notification=messaging.Notification(title=req.title, body=req.body),
                    token=t,
                    data={"deep_link": req.deep_link or ""},
                )
                for t in filtered[:500]
            ]
            response = messaging.send_each(msgs)
            sent_count = response.success_count
            status_str = "sent"

        # Log to Firestore
        notifs = FirestoreCollection("notifications")
        nid = str(uuid.uuid4())
        await notifs.create(nid, {
            "id": nid, "title": req.title, "body": req.body,
            "target": req.target, "sent_count": sent_count, "status": status_str,
        })
        return NotifResponse(sent_count=sent_count, status=status_str,
            message=f"Notification sent to {sent_count} users")

    except Exception as e:
        logger.error(f"Push notification failed: {e}")
        raise HTTPException(status_code=500, detail=f"Push failed: {str(e)}")

@router.get("/stats", response_model=dict)
async def get_stats(_: UserInDB = Depends(require_admin)):
    users = await FirestoreCollection("users").list_all(500)
    return {
        "total_users": len(users),
        "premium_users": sum(1 for u in users if u.get("is_premium")),
        "admin_users": sum(1 for u in users if u.get("is_admin")),
        "active_users": sum(1 for u in users if u.get("is_active")),
    }
