"""
repositories/user_repository.py
Data access layer for User entity.
Only this class touches the users Firestore collection.
"""
import uuid
from datetime import datetime, timezone
from typing import List, Optional

from app.core.firebase import FirestoreCollection  # noqa: F401 (used in type hint + _profiles_col)
from app.core.security import hash_password, verify_password
from app.schemas.user_schema import (
    ProfileCreate, ProfilePublic,
    UpdateProfileRequest, UserCreate, UserInDB,
)


class UserRepository:
    def __init__(self) -> None:
        self._col = FirestoreCollection("users")

    async def get_by_id(self, user_id: str) -> Optional[UserInDB]:
        doc = await self._col.get_by_id(user_id)
        return UserInDB(**doc) if doc else None

    async def get_by_email(self, email: str) -> Optional[UserInDB]:
        docs = await self._col.get_where("email", "==", email.lower(), limit=1)
        return UserInDB(**docs[0]) if docs else None

    async def create(self, payload: UserCreate) -> UserInDB:
        user_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        data = {
            "id": user_id,
            "email": payload.email.lower(),
            "full_name": payload.full_name,
            "phone": payload.phone,
            "hashed_password": hash_password(payload.password),
            "is_active": True,
            "is_premium": False,
            "is_admin": False,
            "user_tier": "free",
            "created_at": now,
            "updated_at": now,
            # Birth details (collected at registration)
            "date_of_birth": payload.date_of_birth,
            "time_of_birth": payload.time_of_birth,
            "place_of_birth": payload.place_of_birth,
            "birth_latitude": payload.birth_latitude,
            "birth_longitude": payload.birth_longitude,
            "birth_timezone": payload.birth_timezone,
            "moon_sign": None,
        }
        doc = await self._col.create(user_id, data)
        return UserInDB(**doc)

    async def verify_credentials(self, email: str, password: str) -> Optional[UserInDB]:
        user = await self.get_by_email(email)
        if not user:
            return None
        if not verify_password(password, user.hashed_password):
            return None
        return user

    async def update_profile(self, user_id: str, payload: UpdateProfileRequest) -> Optional[UserInDB]:
        # Use model_dump with mode='json' so enums are serialized as their string value
        update_data: dict = {
            k: v for k, v in payload.model_dump(mode="json").items() if v is not None
        }
        update_data["updated_at"] = datetime.now(timezone.utc).isoformat()
        # Keep is_premium/is_admin in sync if tier is being updated
        if "user_tier" in update_data:
            tier = update_data["user_tier"]
            update_data["is_premium"] = tier in ("premium", "max", "admin")
            update_data["is_admin"]   = tier == "admin"
        await self._col.update(user_id, update_data)
        return await self.get_by_id(user_id)

    async def update_premium(self, user_id: str, is_premium: bool) -> None:
        await self._col.update(user_id, {"is_premium": is_premium})

    async def save_moon_sign(self, user_id: str, sign: str) -> None:
        await self._col.update(user_id, {"moon_sign": sign})

    async def save_birth_details(self, user_id: str, birth_data: dict) -> None:
        await self._col.update(user_id, {"birth_details": birth_data})

    async def update_tier(self, user_id: str, tier: str) -> None:
        is_premium = tier in ("premium", "max", "admin")
        is_admin   = tier == "admin"
        await self._col.update(user_id, {
            "user_tier":  tier,
            "is_premium": is_premium,
            "is_admin":   is_admin,
        })

    # ── Additional profiles (family/friends) ──────────────────────────────────

    def _profiles_col(self) -> FirestoreCollection:
        return FirestoreCollection("profiles")

    async def list_profiles(self, owner_uid: str) -> List[ProfilePublic]:
        col = self._profiles_col()
        docs = await col.get_where("owner_uid", "==", owner_uid)
        return [ProfilePublic(**d) for d in docs]

    async def add_profile(self, owner_uid: str, payload: ProfileCreate) -> ProfilePublic:
        col = self._profiles_col()
        profile_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        data = {
            "id":             profile_id,
            "owner_uid":      owner_uid,
            "full_name":      payload.full_name,
            "relationship":   payload.relationship,
            "gender":         payload.gender,
            "date_of_birth":  payload.date_of_birth,
            "time_of_birth":  payload.time_of_birth,
            "place_of_birth": payload.place_of_birth,
            "birth_latitude": payload.birth_latitude,
            "birth_longitude": payload.birth_longitude,
            "birth_timezone": payload.birth_timezone,
            "created_at":     now,
        }
        doc = await col.create(profile_id, data)
        return ProfilePublic(**doc)

    async def delete_profile(self, owner_uid: str, profile_id: str) -> bool:
        col = self._profiles_col()
        doc = await col.get_by_id(profile_id)
        if not doc or doc.get("owner_uid") != owner_uid:
            return False
        await col.delete(profile_id)
        return True
