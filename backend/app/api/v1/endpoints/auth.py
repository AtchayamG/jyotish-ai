"""app/api/v1/endpoints/auth.py — with Google Sign In + FCM token update"""
import uuid
from datetime import datetime, timezone
from typing import Annotated, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from app.core.dependencies import CurrentUser, get_user_repository
from app.repositories.user_repository import UserRepository
from app.schemas.user_schema import RefreshRequest, TokenResponse, UpdateFCMToken, UserCreate, UserLogin
from app.services.auth_service import AuthService
from app.core.firebase import FirestoreCollection
from app.core.security import create_access_token, create_refresh_token

router = APIRouter(prefix="/auth", tags=["Auth"])

def _svc(repo: Annotated[UserRepository, Depends(get_user_repository)]) -> AuthService:
    return AuthService(repo)

@router.post("/register", response_model=TokenResponse, status_code=201)
async def register(payload: UserCreate, svc: Annotated[AuthService, Depends(_svc)]):
    return await svc.register(payload)

@router.post("/login", response_model=TokenResponse)
async def login(payload: UserLogin, svc: Annotated[AuthService, Depends(_svc)]):
    return await svc.login(payload)

@router.post("/refresh", response_model=TokenResponse)
async def refresh(payload: RefreshRequest, svc: Annotated[AuthService, Depends(_svc)]):
    return await svc.refresh(payload.refresh_token)

class GoogleAuthRequest(BaseModel):
    id_token: str; email: str; name: str; google_uid: Optional[str] = None

@router.post("/google", response_model=TokenResponse)
async def google_auth(payload: GoogleAuthRequest):
    """Verify Google ID token and return JWT. Creates account if first login."""
    try:
        from firebase_admin import auth as firebase_auth
        decoded = firebase_auth.verify_id_token(payload.id_token)
        email = decoded.get("email", payload.email).lower()
        name  = decoded.get("name",  payload.name)
        uid   = decoded.get("uid",   payload.google_uid or "")
    except Exception as e:
        # Dev mode: trust the payload directly (no token verification)
        import os
        if os.getenv("APP_ENV") == "production":
            raise HTTPException(status_code=401, detail=f"Invalid Google token: {e}")
        email = payload.email.lower()
        name  = payload.name
        uid   = payload.google_uid or ""

    users = FirestoreCollection("users")
    # Find or create user
    existing = await users.get_where("email", "==", email, limit=1)
    if existing:
        user_data = existing[0]
    else:
        user_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        user_data = {
            "id": user_id, "email": email, "full_name": name,
            "phone": None, "hashed_password": "",
            "is_active": True, "is_premium": False, "is_admin": False,
            "google_uid": uid, "created_at": now, "updated_at": now,
        }
        await users.create(user_id, user_data)

    from app.schemas.user_schema import UserPublic, TokenResponse as TR
    user_pub = UserPublic(
        id=user_data["id"], email=user_data["email"],
        full_name=user_data.get("full_name", name), phone=user_data.get("phone"),
        is_premium=user_data.get("is_premium", False),
        is_admin=user_data.get("is_admin", False),
        created_at=user_data.get("created_at", ""),
    )
    return TR(
        access_token=create_access_token(user_data["id"]),
        refresh_token=create_refresh_token(user_data["id"]),
        user=user_pub,
    )

@router.post("/fcm-token", status_code=204)
async def update_fcm_token(payload: UpdateFCMToken, user: CurrentUser):
    """Save FCM push notification token for this user."""
    users = FirestoreCollection("users")
    await users.update(user.id, {"fcm_token": payload.fcm_token})
