"""
repositories/astrology_repository.py
All calls to Prokerala API go through this repository.
Uses real OAuth2 client credentials flow.
Falls back to mock data when credentials are absent (local dev without keys).

Prokerala Credentials (set in Render env vars):
  PROKERALA_CLIENT_ID     = e87c610a-a146-43c9-a8f5-274fabdd3b1c
  PROKERALA_CLIENT_SECRET = ag1OUvgqM1S2Uz2A7DKOGeu8AEXoXs5P35IMbK6c
"""
import logging
import time
from typing import Any, Dict, Optional

from app.core.config import settings
from app.core.http_client import http_client
from app.schemas.astrology_schema import BirthDetails

logger = logging.getLogger(__name__)

# ── Token cache ───────────────────────────────────────────────────────────────
_token_cache: Dict[str, Any] = {"token": None, "expires_at": 0}


class AstrologyRepository:

    # ── OAuth Token ───────────────────────────────────────────────────────────

    async def _get_token(self) -> str:
        now = time.time()

        # Return cached token if still valid (refresh 60s before expiry)
        if _token_cache["token"] and now < _token_cache["expires_at"] - 60:
            return _token_cache["token"]

        if not settings.PROKERALA_CLIENT_ID:
            logger.info("[AstroRepo] No Prokerala credentials — using mock data")
            return "mock_token"

        logger.info("[AstroRepo] Fetching new Prokerala OAuth token...")
        resp = await http_client.post(
            "https://api.prokerala.com/token",
            data={
                "grant_type":    "client_credentials",
                "client_id":     settings.PROKERALA_CLIENT_ID,
                "client_secret": settings.PROKERALA_CLIENT_SECRET,
            },
        )

        token   = resp["access_token"]
        expires = resp.get("expires_in", 3600)

        _token_cache["token"]      = token
        _token_cache["expires_at"] = now + expires

        logger.info(f"[AstroRepo] Token acquired, expires in {expires}s")
        return token

    # ── Shared helpers ────────────────────────────────────────────────────────

    def _birth_params(self, birth: BirthDetails) -> Dict[str, Any]:
        """Build Prokerala query params from birth details."""
        # Format: 2026-04-10T06:30:00+05:30
        tz_hours   = int(birth.timezone)
        tz_minutes = int(abs(birth.timezone % 1) * 60)
        tz_sign    = "+" if birth.timezone >= 0 else "-"
        tz_str     = f"{tz_sign}{abs(tz_hours):02d}:{tz_minutes:02d}"
        datetime_str = (
            f"{birth.year}-{birth.month:02d}-{birth.day:02d}"
            f"T{birth.hour:02d}:{birth.minute:02d}:00{tz_str}"
        )
        return {
            "ayanamsa":    birth.ayanamsa,
            "coordinates": f"{birth.latitude},{birth.longitude}",
            "datetime":    datetime_str,
        }

    async def _prokerala_get(
        self,
        endpoint: str,
        params: Dict[str, Any],
    ) -> Dict[str, Any]:
        token = await self._get_token()
        if token == "mock_token":
            return {}  # caller handles empty dict → mock fallback
        return await http_client.get(
            f"{settings.PROKERALA_BASE_URL}/{endpoint}",
            headers={"Authorization": f"Bearer {token}"},
            params=params,
        )

    # ── Birth Chart / Planet Positions ────────────────────────────────────────

    async def get_birth_chart(self, birth: BirthDetails) -> Dict[str, Any]:
        raw = await self._prokerala_get(
            "planet-position", self._birth_params(birth)
        )
        return raw if raw else self._mock_birth_chart()

    async def get_kundli_chart(self, birth: BirthDetails) -> Dict[str, Any]:
        raw = await self._prokerala_get(
            "kundli", self._birth_params(birth)
        )
        return raw if raw else self._mock_kundli()

    # ── Horoscope ─────────────────────────────────────────────────────────────

    async def get_horoscope(self, sign: str, horo_type: str) -> Dict[str, Any]:
        raw = await self._prokerala_get(
            f"{horo_type}-horoscope",
            {"sign": sign.lower()},
        )
        return raw if raw else self._mock_horoscope(sign, horo_type)

    # ── Matchmaking ───────────────────────────────────────────────────────────

    async def get_guna_milan(
        self, birth1: BirthDetails, birth2: BirthDetails
    ) -> Dict[str, Any]:
        p1 = self._birth_params(birth1)
        # Prokerala uses "girl_" prefix for second person in matching
        p2 = {f"girl_{k}": v for k, v in self._birth_params(birth2).items()}
        raw = await self._prokerala_get(
            "kundli-matching/ashtakoota",
            {**p1, **p2},
        )
        return raw if raw else self._mock_guna_milan()

    # ── Muhurtham ─────────────────────────────────────────────────────────────

    async def get_muhurtham(
        self,
        muhurtham_type: str,
        from_date: str,
        to_date: str,
        lat: float,
        lng: float,
    ) -> Dict[str, Any]:
        raw = await self._prokerala_get(
            f"muhurta/{muhurtham_type}",
            {
                "coordinates": f"{lat},{lng}",
                "from_date":   from_date,
                "to_date":     to_date,
                "ayanamsa":    "lahiri",
            },
        )
        return raw if raw else self._mock_muhurtham(muhurtham_type)

    # ── Mock data (used when no API keys / as fallback) ───────────────────────

    def _mock_birth_chart(self) -> Dict[str, Any]:
        return {
            "data": {
                "planets": [
                    {"id": 0, "name": "Sun",     "longitude": 4.38,   "is_retrograde": False,
                     "rasi": {"id": 1,  "name": "Mesha"},
                     "nakshatra": {"id": 1,  "name": "Aswini"},    "nakshatra_pada": 1},
                    {"id": 1, "name": "Moon",    "longitude": 228.12, "is_retrograde": False,
                     "rasi": {"id": 8,  "name": "Vrischika"},
                     "nakshatra": {"id": 17, "name": "Anuradha"},   "nakshatra_pada": 3},
                    {"id": 2, "name": "Mars",    "longitude": 298.2,  "is_retrograde": False,
                     "rasi": {"id": 10, "name": "Makara"},
                     "nakshatra": {"id": 23, "name": "Dhanishta"},  "nakshatra_pada": 2},
                    {"id": 3, "name": "Mercury", "longitude": 102.75, "is_retrograde": False,
                     "rasi": {"id": 3,  "name": "Mithuna"},
                     "nakshatra": {"id": 6,  "name": "Ardra"},      "nakshatra_pada": 1},
                    {"id": 4, "name": "Venus",   "longitude": 337.55, "is_retrograde": False,
                     "rasi": {"id": 12, "name": "Meena"},
                     "nakshatra": {"id": 26, "name": "Uttarabhadra"}, "nakshatra_pada": 2},
                    {"id": 5, "name": "Jupiter", "longitude": 102.91, "is_retrograde": False,
                     "rasi": {"id": 4,  "name": "Karka"},
                     "nakshatra": {"id": 8,  "name": "Pushya"},     "nakshatra_pada": 4},
                    {"id": 6, "name": "Saturn",  "longitude": 293.18, "is_retrograde": True,
                     "rasi": {"id": 10, "name": "Makara"},
                     "nakshatra": {"id": 22, "name": "Sravana"},    "nakshatra_pada": 3},
                    {"id": 7, "name": "Rahu",    "longitude": 102.33, "is_retrograde": True,
                     "rasi": {"id": 3,  "name": "Mithuna"},
                     "nakshatra": {"id": 6,  "name": "Ardra"},      "nakshatra_pada": 2},
                    {"id": 8, "name": "Ketu",    "longitude": 282.33, "is_retrograde": True,
                     "rasi": {"id": 9,  "name": "Dhanu"},
                     "nakshatra": {"id": 20, "name": "Purvashadha"}, "nakshatra_pada": 2},
                ]
            }
        }

    def _mock_kundli(self) -> Dict[str, Any]:
        return {
            "data": {
                "ascendant":          {"rasi": {"name": "Mesha"}, "degree": 4.38},
                "nakshatra":          {"name": "Aswini", "pada": 2},
                "tithi":              {"name": "Ekadashi"},
                "yoga":               {"name": "Siddhi"},
                "karana":             {"name": "Bava"},
                "current_mahadasha":  "Rahu",
                "current_antardasha": "Venus",
            }
        }

    def _mock_horoscope(self, sign: str, horo_type: str) -> Dict[str, Any]:
        predictions = {
            "Mesha":     "Jupiter aspects your 10th house bringing career breakthroughs. Excellent period for professional endeavours and public recognition.",
            "Vrischika": "Mars in your favour strengthens determination. Emotional clarity helps resolve long-standing personal issues.",
            "Karka":     "Moon in your sign brings emotional depth. Nurturing relationships and home matters are highlighted today.",
            "Simha":     "Sun energises your natural leadership. Creative projects and self-expression bring rewards.",
        }
        text = predictions.get(
            sign,
            "The planetary alignment favours steady progress. Maintain patience and focus on your goals."
        )
        return {
            "data": {
                "prediction":    text,
                "lucky_number":  7,
                "lucky_color":   "Royal Blue",
                "lucky_gemstone":"Blue Sapphire",
                "career_score":  8.5,
                "love_score":    6.0,
                "health_score":  7.5,
                "finance_score": 7.0,
                "overall_score": 7.8,
            }
        }

    def _mock_guna_milan(self) -> Dict[str, Any]:
        return {
            "data": {
                "total_points": 28,
                "max_points":   36,
                "kutas": [
                    {"name": "Varna",       "total": 1, "obtained": 1},
                    {"name": "Vashya",      "total": 2, "obtained": 2},
                    {"name": "Tara",        "total": 3, "obtained": 3},
                    {"name": "Yoni",        "total": 4, "obtained": 4},
                    {"name": "Graha Maitri","total": 5, "obtained": 5},
                    {"name": "Gana",        "total": 6, "obtained": 5},
                    {"name": "Bhakoot",     "total": 7, "obtained": 7},
                    {"name": "Nadi",        "total": 8, "obtained": 0},
                ],
                "nadi_dosha": True,
            }
        }

    def _mock_muhurtham(self, mtype: str) -> Dict[str, Any]:
        return {
            "data": {
                "muhurthas": [
                    {"date": "2026-04-12", "start": "07:23", "end": "09:47",
                     "quality": "Excellent", "nakshatra": "Rohini",  "tithi": "Tritiya"},
                    {"date": "2026-04-18", "start": "06:15", "end": "08:00",
                     "quality": "Good",      "nakshatra": "Hasta",   "tithi": "Panchami"},
                    {"date": "2026-04-21", "start": "10:00", "end": "12:30",
                     "quality": "Good",      "nakshatra": "Chitra",  "tithi": "Ashtami"},
                ]
            }
        }
