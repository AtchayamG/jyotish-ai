"""
api/v1/endpoints/astrology.py
Kundli, Horoscope, Matchmaking, Muhurtham, AI Chat endpoints.
"""
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException

from app.core.dependencies import CurrentUser
from app.repositories.astrology_repository import AstrologyRepository
from app.repositories.user_repository import UserRepository
from app.schemas.astrology_schema import (
    AIChatRequest,
    AIChatResponse,
    BirthDetails,
    HoroscopeRequest,
    HoroscopeResponse,
    HoroscopeType,
    KundliResponse,
    MatchRequest,
    MatchResponse,
    MuhurthamRequest,
    MuhurthamResponse,
    ZodiacSign,
)
from app.services.ai_chat_service import AIChatService
from app.services.astrology_service import AstrologyService

router = APIRouter(prefix="/astrology", tags=["Astrology"])


def _astro_service() -> AstrologyService:
    return AstrologyService(AstrologyRepository())


def _chat_service() -> AIChatService:
    return AIChatService()


# ── Kundli ────────────────────────────────────────────────────────────────────

@router.post("/kundli", response_model=KundliResponse)
async def get_kundli(
    birth: BirthDetails,
    user: CurrentUser,
    svc: Annotated[AstrologyService, Depends(_astro_service)],
):
    """Generate Janma Kundli (birth chart) with planet positions and Dasha."""
    result = await svc.get_kundli(birth)
    # Cache the moon sign so my-horoscope is faster next time
    try:
        repo = UserRepository()
        await repo.save_moon_sign(user.id, result.summary.rasi)
    except Exception:
        pass
    return result


@router.get("/my-kundli", response_model=KundliResponse)
async def get_my_kundli(
    user: CurrentUser,
    svc: Annotated[AstrologyService, Depends(_astro_service)],
):
    """Generate Kundli using the user's stored birth details — no body required."""
    if not user.birth_latitude or not user.date_of_birth:
        raise HTTPException(
            status_code=400,
            detail="Birth details not set. Please update your profile with DOB, TOB, and place of birth.",
        )
    birth = _birth_from_user(user)
    result = await svc.get_kundli(birth)
    try:
        repo = UserRepository()
        await repo.save_moon_sign(user.id, result.summary.rasi)
    except Exception:
        pass
    return result


# ── Horoscope ─────────────────────────────────────────────────────────────────

@router.post("/horoscope", response_model=HoroscopeResponse)
async def get_horoscope(
    req: HoroscopeRequest,
    svc: Annotated[AstrologyService, Depends(_astro_service)],
):
    """Get horoscope prediction. No auth required for basic daily horoscope."""
    return await svc.get_horoscope(req.zodiac_sign, req.horoscope_type, req.language)


@router.get("/horoscope/{sign}", response_model=HoroscopeResponse)
async def get_horoscope_by_sign(
    sign: ZodiacSign,
    svc: Annotated[AstrologyService, Depends(_astro_service)],
):
    """Quick daily horoscope by sign — public endpoint."""
    return await svc.get_horoscope(sign, HoroscopeType.DAILY, "en")


@router.get("/my-horoscope", response_model=HoroscopeResponse)
async def my_horoscope(
    user: CurrentUser,
    svc: Annotated[AstrologyService, Depends(_astro_service)],
    htype: HoroscopeType = HoroscopeType.DAILY,
):
    """
    Personalised horoscope using the user's stored birth details.
    If moon sign is already cached it returns instantly; otherwise it
    computes the Kundli first (Prokerala call) and caches the result.
    """
    if not user.birth_latitude or not user.date_of_birth:
        raise HTTPException(
            status_code=400,
            detail="Birth details not set. Please update your profile with DOB, TOB, and place of birth.",
        )

    # Fast path: use cached moon sign
    if user.moon_sign:
        try:
            sign = ZodiacSign(user.moon_sign)
            return await svc.get_horoscope(sign, htype, "en")
        except ValueError:
            pass  # invalid cached value — fall through and recompute

    # Compute moon sign via Prokerala kundli
    birth = _birth_from_user(user)
    kundli = await svc.get_kundli(birth)
    moon_rasi = kundli.summary.rasi

    # Persist moon sign for future fast-path
    try:
        repo = UserRepository()
        await repo.save_moon_sign(user.id, moon_rasi)
    except Exception:
        pass

    try:
        sign = ZodiacSign(moon_rasi)
    except ValueError:
        sign = ZodiacSign.MESHA  # safe default

    return await svc.get_horoscope(sign, htype, "en")


# ── Matchmaking ───────────────────────────────────────────────────────────────

@router.post("/match", response_model=MatchResponse)
async def get_match(
    req: MatchRequest,
    _: CurrentUser,
    svc: Annotated[AstrologyService, Depends(_astro_service)],
):
    """Guna Milan (Ashtakoota) compatibility analysis."""
    return await svc.get_match(req)


# ── Muhurtham ─────────────────────────────────────────────────────────────────

@router.post("/muhurtham", response_model=MuhurthamResponse)
async def get_muhurtham(
    req: MuhurthamRequest,
    _: CurrentUser,
    svc: Annotated[AstrologyService, Depends(_astro_service)],
):
    """Find auspicious muhurtham slots for a given event type and date range."""
    return await svc.get_muhurtham(req)


# ── AI Chat ───────────────────────────────────────────────────────────────────

@router.post("/chat", response_model=AIChatResponse)
async def ai_chat(
    req: AIChatRequest,
    current_user: CurrentUser,
    svc: Annotated[AIChatService, Depends(_chat_service)],
):
    """AI-powered Vedic astrology chatbot — authenticated, chart-aware."""
    # Build birth details from stored profile (no need for client to send)
    birth = _birth_from_user(current_user) if current_user.date_of_birth else None
    return await svc.chat(req, user_id=current_user.id, birth=birth)


# ── Helpers ───────────────────────────────────────────────────────────────────

def _birth_from_user(user) -> BirthDetails:
    """Build a BirthDetails object from a user's stored profile data."""
    dob = (user.date_of_birth or "1990-01-01").split("-")
    tob = (user.time_of_birth or "06:00").split(":")
    return BirthDetails(
        name=user.full_name,
        year=int(dob[0]),
        month=int(dob[1]),
        day=int(dob[2]),
        hour=int(tob[0]),
        minute=int(tob[1]) if len(tob) > 1 else 0,
        latitude=user.birth_latitude or 13.0827,
        longitude=user.birth_longitude or 80.2707,
        timezone=user.birth_timezone or 5.5,
    )
