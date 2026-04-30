"""
services/auth_service.py
Authentication business logic.
Orchestrates repository calls and token generation.
"""
from fastapi import HTTPException, status

from app.core.security import create_access_token, create_refresh_token, decode_token
from app.repositories.user_repository import UserRepository
from app.schemas.user_schema import (
    TokenResponse,
    UserCreate,
    UserLogin,
    UserPublic,
)


class AuthService:
    def __init__(self, user_repo: UserRepository) -> None:
        self._repo = user_repo

    async def register(self, payload: UserCreate) -> TokenResponse:
        existing = await self._repo.get_by_email(payload.email)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered",
            )

        user = await self._repo.create(payload)
        return self._build_token_response(user)

    async def login(self, payload: UserLogin) -> TokenResponse:
        user = await self._repo.verify_credentials(payload.email, payload.password)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            )
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account deactivated",
            )
        return self._build_token_response(user)

    async def refresh(self, refresh_token: str) -> TokenResponse:
        user_id = decode_token(refresh_token)
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token",
            )
        user = await self._repo.get_by_id(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return self._build_token_response(user)

    def _build_token_response(self, user) -> TokenResponse:
        return TokenResponse(
            access_token=create_access_token(user.id),
            refresh_token=create_refresh_token(user.id),
            user=UserPublic(
                id=user.id,
                email=user.email,
                full_name=user.full_name,
                phone=user.phone,
                is_premium=user.is_premium,
                is_admin=user.is_admin,
                created_at=user.created_at,
                date_of_birth=getattr(user, "date_of_birth", None),
                time_of_birth=getattr(user, "time_of_birth", None),
                place_of_birth=getattr(user, "place_of_birth", None),
                birth_latitude=getattr(user, "birth_latitude", None),
                birth_longitude=getattr(user, "birth_longitude", None),
                birth_timezone=getattr(user, "birth_timezone", None),
                moon_sign=getattr(user, "moon_sign", None),
            ),
        )
