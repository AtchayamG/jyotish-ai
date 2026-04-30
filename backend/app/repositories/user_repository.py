"""
repositories/user_repository.py
Data access layer for User entity.
Only this class touches the users Firestore collection.
"""
import uuid
from datetime import datetime, timezone
from typing import Optional

from app.core.firebase import FirestoreCollection
from app.core.security import hash_password, verify_password
from app.schemas.user_schema import UpdateProfileRequest, UserCreate, UserInDB


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
        update_data: dict = {
            k: v for k, v in payload.model_dump().items() if v is not None
        }
        update_data["updated_at"] = datetime.now(timezone.utc).isoformat()
        await self._col.update(user_id, update_data)
        return await self.get_by_id(user_id)

    async def update_premium(self, user_id: str, is_premium: bool) -> None:
        await self._col.update(user_id, {"is_premium": is_premium})

    async def save_moon_sign(self, user_id: str, sign: str) -> None:
        await self._col.update(user_id, {"moon_sign": sign})

    async def save_birth_details(self, user_id: str, birth_data: dict) -> None:
        await self._col.update(user_id, {"birth_details": birth_data})
