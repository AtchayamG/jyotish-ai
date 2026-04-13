"""
api/v1/endpoints/astrology.py
Kundli, Horoscope, Matchmaking, Muhurtham, AI Chat endpoints.
"""
from typing import Annotated

from fastapi import APIRouter, Depends

from app.core.dependencies import CurrentUser
from app.repositories.astrology_repository import AstrologyRepository
from app.schemas.astrology_schema import (
    AIChatRequest,
    AIChatResponse,
    BirthDetails,
    HoroscopeRequest,
    HoroscopeResponse,
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
    _: CurrentUser,
    svc: Annotated[AstrologyService, Depends(_astro_service)],
):
    """Generate Janma Kundli (birth chart) with planet positions and Dasha."""
    return await svc.get_kundli(birth)


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
    from app.schemas.astrology_schema import HoroscopeType
    return await svc.get_horoscope(sign, HoroscopeType.DAILY, "en")


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
    svc: Annotated[AIChatService, Depends(_chat_service)],
):
    """AI-powered Vedic astrology chatbot."""
    return await svc.chat(req)
