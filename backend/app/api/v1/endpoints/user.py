"""
api/v1/endpoints/user.py
User profile — GET and PUT endpoints.
"""
from typing import Annotated

from fastapi import APIRouter, Depends

from app.core.dependencies import CurrentUser, get_user_repository
from app.repositories.user_repository import UserRepository
from app.schemas.user_schema import UpdateProfileRequest, UserPublic

router = APIRouter(prefix="/user", tags=["User"])


@router.get("/profile", response_model=UserPublic)
async def get_profile(user: CurrentUser) -> UserPublic:
    """Return the authenticated user's full profile including birth details."""
    return UserPublic(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        phone=user.phone,
        is_premium=user.is_premium,
        is_admin=user.is_admin,
        created_at=user.created_at,
        date_of_birth=user.date_of_birth,
        time_of_birth=user.time_of_birth,
        place_of_birth=user.place_of_birth,
        birth_latitude=user.birth_latitude,
        birth_longitude=user.birth_longitude,
        birth_timezone=user.birth_timezone,
        moon_sign=user.moon_sign,
    )


@router.put("/profile", response_model=UserPublic)
async def update_profile(
    payload: UpdateProfileRequest,
    user: CurrentUser,
    repo: Annotated[UserRepository, Depends(get_user_repository)],
) -> UserPublic:
    """Update user profile fields (birth details, name, phone)."""
    updated = await repo.update_profile(user.id, payload)
    if not updated:
        # Fallback: return current user unchanged
        updated = user
    return UserPublic(
        id=updated.id,
        email=updated.email,
        full_name=updated.full_name,
        phone=updated.phone,
        is_premium=updated.is_premium,
        is_admin=updated.is_admin,
        created_at=updated.created_at,
        date_of_birth=updated.date_of_birth,
        time_of_birth=updated.time_of_birth,
        place_of_birth=updated.place_of_birth,
        birth_latitude=updated.birth_latitude,
        birth_longitude=updated.birth_longitude,
        birth_timezone=updated.birth_timezone,
        moon_sign=updated.moon_sign,
    )
