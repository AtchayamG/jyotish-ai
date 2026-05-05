"""
api/v1/endpoints/user.py
User profile — GET / PUT endpoints + additional profiles CRUD.
"""
from typing import Annotated, List

from fastapi import APIRouter, Depends, HTTPException, status

from app.core.dependencies import CurrentUser, get_user_repository
from app.repositories.user_repository import UserRepository
from app.schemas.user_schema import (
    ProfileCreate, ProfilePublic,
    UpdateProfileRequest, UserPublic, UserTier,
)

router = APIRouter(prefix="/user", tags=["User"])


def _to_public(user) -> UserPublic:
    return UserPublic(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        phone=user.phone,
        is_premium=user.is_premium,
        is_admin=user.is_admin,
        user_tier=user.user_tier,
        created_at=user.created_at,
        date_of_birth=user.date_of_birth,
        time_of_birth=user.time_of_birth,
        place_of_birth=user.place_of_birth,
        birth_latitude=user.birth_latitude,
        birth_longitude=user.birth_longitude,
        birth_timezone=user.birth_timezone,
        moon_sign=user.moon_sign,
    )


@router.get("/profile", response_model=UserPublic)
async def get_profile(user: CurrentUser) -> UserPublic:
    """Return the authenticated user's full profile including birth details."""
    return _to_public(user)


@router.put("/profile", response_model=UserPublic)
async def update_profile(
    payload: UpdateProfileRequest,
    user: CurrentUser,
    repo: Annotated[UserRepository, Depends(get_user_repository)],
) -> UserPublic:
    """Update user profile fields (birth details, name, phone, tier)."""
    updated = await repo.update_profile(user.id, payload)
    return _to_public(updated or user)


# ── Additional profiles (family / friends) ────────────────────────────────────

_TIER_LIMITS = {
    UserTier.free:    0,
    UserTier.premium: 2,
    UserTier.max:     5,
    UserTier.admin:   999,
}


@router.get("/profiles", response_model=List[ProfilePublic])
async def list_profiles(
    user: CurrentUser,
    repo: Annotated[UserRepository, Depends(get_user_repository)],
) -> List[ProfilePublic]:
    """List additional profiles owned by the current user."""
    return await repo.list_profiles(user.id)


@router.post("/profiles", response_model=ProfilePublic, status_code=status.HTTP_201_CREATED)
async def add_profile(
    payload: ProfileCreate,
    user: CurrentUser,
    repo: Annotated[UserRepository, Depends(get_user_repository)],
) -> ProfilePublic:
    """Add a new additional profile (family member / friend)."""
    limit = _TIER_LIMITS.get(user.user_tier, 0)
    existing = await repo.list_profiles(user.id)
    if len(existing) >= limit:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Your {user.user_tier.value} plan allows {limit} additional profiles. Upgrade to add more.",
        )
    return await repo.add_profile(user.id, payload)


@router.delete("/profiles/{profile_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_profile(
    profile_id: str,
    user: CurrentUser,
    repo: Annotated[UserRepository, Depends(get_user_repository)],
) -> None:
    """Delete an additional profile owned by the current user."""
    deleted = await repo.delete_profile(user.id, profile_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found or access denied.",
        )
