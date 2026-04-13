"""
schemas/astrology_schema.py
All request/response schemas for Kundli, Horoscope, Matchmaking, etc.
"""
from typing import List, Optional, Annotated
from pydantic import BaseModel, Field
from enum import Enum


# ── Shared ────────────────────────────────────────────────────────────────────

class BirthDetails(BaseModel):
    name: str
    year: int = Field(..., ge=1900, le=2100)
    month: int = Field(..., ge=1, le=12)
    day: int = Field(..., ge=1, le=31)
    hour: int = Field(..., ge=0, le=23)
    minute: int = Field(..., ge=0, le=59)
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    timezone: float = Field(default=5.5, description="UTC offset, e.g. 5.5 for IST")
    ayanamsa: str = Field(default="lahiri", description="lahiri | raman | krishnamurti")


class ZodiacSign(str, Enum):
    MESHA = "Mesha"
    VRISHABHA = "Vrishabha"
    MITHUNA = "Mithuna"
    KARKA = "Karka"
    SIMHA = "Simha"
    KANYA = "Kanya"
    TULA = "Tula"
    VRISCHIKA = "Vrischika"
    DHANU = "Dhanu"
    MAKARA = "Makara"
    KUMBHA = "Kumbha"
    MEENA = "Meena"


# ── Kundli ────────────────────────────────────────────────────────────────────

class PlanetPosition(BaseModel):
    name: str
    symbol: str
    rasi: str
    degree: str
    nakshatra: str
    pada: int
    house: int
    is_retrograde: bool
    status: str


class ChartSummary(BaseModel):
    lagna: str
    lagna_lord: str
    rasi: str
    rasi_lord: str
    nakshatra: str
    pada: int
    tithi: str
    yoga: str
    karana: str
    ayana: str


class DashaEntry(BaseModel):
    planet: str
    start_date: str
    end_date: str
    is_current: bool
    antardasha: Optional[List["DashaEntry"]] = None


class KundliResponse(BaseModel):
    birth_details: BirthDetails
    summary: ChartSummary
    planets: List[PlanetPosition]
    current_dasha: str
    dashas: List[DashaEntry]
    ai_insight: Optional[str] = None


# ── Horoscope ─────────────────────────────────────────────────────────────────

class HoroscopeType(str, Enum):
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"


class CategoryScore(BaseModel):
    career: float = Field(ge=0, le=10)
    love: float = Field(ge=0, le=10)
    health: float = Field(ge=0, le=10)
    finance: float = Field(ge=0, le=10)


class HoroscopeRequest(BaseModel):
    zodiac_sign: ZodiacSign
    horoscope_type: HoroscopeType = HoroscopeType.DAILY
    language: str = "en"


class HoroscopeResponse(BaseModel):
    zodiac_sign: str
    type: str
    date_range: str
    overall_score: float
    scores: CategoryScore
    prediction: str
    lucky_number: int
    lucky_color: str
    lucky_gemstone: str
    do_today: List[str]
    avoid_today: List[str]


# ── Matchmaking ───────────────────────────────────────────────────────────────

class MatchRequest(BaseModel):
    person1: BirthDetails
    person2: BirthDetails


class KutaScore(BaseModel):
    name: str
    max_score: int
    obtained_score: int
    description: str


class DoshaInfo(BaseModel):
    has_dosha: bool
    dosha_type: Optional[str] = None
    severity: Optional[str] = None
    remedy: Optional[str] = None


class MatchResponse(BaseModel):
    total_score: int
    max_score: int = 36
    percentage: float
    verdict: str
    kuta_scores: List[KutaScore]
    dosha: DoshaInfo
    ai_analysis: Optional[str] = None


# ── Muhurtham ─────────────────────────────────────────────────────────────────

class MuhurthamType(str, Enum):
    VIVAH = "vivah"
    GRIHAPRAVESH = "grihapravesh"
    VEHICLE = "vehicle"
    BUSINESS = "business"
    TRAVEL = "travel"


class MuhurthamRequest(BaseModel):
    muhurtham_type: MuhurthamType
    from_date: str
    to_date: str
    latitude: float
    longitude: float
    timezone: float = 5.5


class MuhurthamSlot(BaseModel):
    date: str
    start_time: str
    end_time: str
    quality: str
    nakshatra: str
    tithi: str


class MuhurthamResponse(BaseModel):
    muhurtham_type: str
    slots: List[MuhurthamSlot]


# ── AI Chat ───────────────────────────────────────────────────────────────────

class ChatMessage(BaseModel):
    role: str
    content: str


class AIChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=1000)
    # Fixed: use Annotated with max_length for list in pydantic v2
    history: Annotated[List[ChatMessage], Field(max_length=20)] = []
    language: str = "en"
    user_birth_details: Optional[BirthDetails] = None


class AIChatResponse(BaseModel):
    reply: str
    suggested_questions: List[str] = []


# ── Remedies ──────────────────────────────────────────────────────────────────

class RemedyResponse(BaseModel):
    planet: str
    remedy_type: str
    remedy: str
    frequency: str
    timing: Optional[str] = None
