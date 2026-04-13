"""
repositories/user_repository.py
Data access layer for User entity.
Only this class touches the users Firestore collection.
"""
import uuid
from typing import Optional

from app.core.firebase import FirestoreCollection
from app.core.security import hash_password, verify_password
from app.schemas.user_schema import UserCreate, UserInDB


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
        data = {
            "id": user_id,
            "email": payload.email.lower(),
            "full_name": payload.full_name,
            "phone": payload.phone,
            "hashed_password": hash_password(payload.password),
            "is_active": True,
            "is_premium": False,
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

    async def update_premium(self, user_id: str, is_premium: bool) -> None:
        await self._col.update(user_id, {"is_premium": is_premium})

    async def save_birth_details(self, user_id: str, birth_data: dict) -> None:
        await self._col.update(user_id, {"birth_details": birth_data})
