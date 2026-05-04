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
        try:
            resp = await http_client.post(
                "https://api.prokerala.com/token",
                data={
                    "grant_type":    "client_credentials",
                    "client_id":     settings.PROKERALA_CLIENT_ID,
                    "client_secret": settings.PROKERALA_CLIENT_SECRET,
                },
            )
        except Exception as e:
            logger.error(f"[AstroRepo] Failed to fetch Prokerala token: {e}")
            return "mock_token"

        token   = resp.get("access_token", "")
        expires = resp.get("expires_in", 3600)

        if not token:
            logger.error(f"[AstroRepo] No access_token in Prokerala response: {resp}")
            return "mock_token"

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
        try:
            return await http_client.get(
                f"{settings.PROKERALA_BASE_URL}/{endpoint}",
                headers={"Authorization": f"Bearer {token}"},
                params=params,
            )
        except Exception as e:
            logger.error(f"[AstroRepo] Prokerala call failed for '{endpoint}': {e}")
            return {}  # triggers mock fallback in callers

    # ── Birth Chart / Planet Positions ────────────────────────────────────────
    # Primary: direct Swiss Ephemeris computation (accurate, no external API)
    # Fallback: Prokerala API → mock data

    async def get_birth_chart(self, birth: BirthDetails) -> Dict[str, Any]:
        computed = self._compute_chart(birth)
        if computed:
            return computed["chart"]
        # Prokerala fallback
        raw = await self._prokerala_get("planet-position", self._birth_params(birth))
        return raw if raw else self._mock_birth_chart()

    async def get_kundli_chart(self, birth: BirthDetails) -> Dict[str, Any]:
        computed = self._compute_chart(birth)
        if computed:
            return computed["kundli"]
        # Prokerala fallback
        raw = await self._prokerala_get("kundli", self._birth_params(birth))
        return raw if raw else self._mock_kundli()

    def _compute_chart(self, birth: BirthDetails) -> Dict[str, Any]:
        """Try Swiss Ephemeris direct computation. Returns {} on failure."""
        try:
            from app.services.astro_compute import compute_chart
            result = compute_chart(
                year=birth.year, month=birth.month, day=birth.day,
                hour=birth.hour, minute=birth.minute,
                latitude=birth.latitude, longitude=birth.longitude,
                timezone=birth.timezone,
            )
            return result if result else {}
        except Exception as exc:
            logger.warning(f"[AstroRepo] Direct computation failed: {exc}")
            return {}

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
        # Full per-rasi data for all 12 signs
        _RASI_DATA: Dict[str, Any] = {
            "Mesha": {
                "prediction": (
                    "Jupiter's beneficial aspect on your 10th house signals professional breakthroughs and public recognition. "
                    "Mars, your ruling planet, grants courage to initiate bold ventures. "
                    "Financial gains come through decisive action — channel your natural energy constructively."
                ),
                "lucky_number": 9, "lucky_color": "Red", "lucky_gemstone": "Red Coral",
                "career_score": 8.5, "love_score": 6.5, "health_score": 7.5, "finance_score": 8.0,
                "do_today": ["Take initiative on pending projects", "Connect with senior mentors"],
                "avoid_today": ["Impulsive financial decisions", "Confrontations with authority figures"],
            },
            "Vrishabha": {
                "prediction": (
                    "Venus, your ruling planet, showers grace on personal relationships and creative pursuits. "
                    "Financial stability improves as Saturn's steady influence favours disciplined savings. "
                    "Your patience and persistence will yield tangible, lasting results."
                ),
                "lucky_number": 6, "lucky_color": "White", "lucky_gemstone": "Diamond",
                "career_score": 7.5, "love_score": 8.5, "health_score": 7.0, "finance_score": 8.0,
                "do_today": ["Focus on long-term financial planning", "Nurture close relationships"],
                "avoid_today": ["Stubbornness in negotiations", "Overspending on luxuries"],
            },
            "Mithuna": {
                "prediction": (
                    "Mercury sharpens your intellect and communication skills — ideal for negotiations and new learning. "
                    "Opportunities arise through networking; your versatility is your greatest asset. "
                    "Keep an open mind and explore multiple avenues simultaneously."
                ),
                "lucky_number": 5, "lucky_color": "Green", "lucky_gemstone": "Emerald",
                "career_score": 8.0, "love_score": 7.0, "health_score": 7.5, "finance_score": 7.0,
                "do_today": ["Network actively and share ideas", "Read and expand your knowledge"],
                "avoid_today": ["Scattering energy across too many tasks", "Spreading unverified information"],
            },
            "Karka": {
                "prediction": (
                    "The Moon, your ruling planet, deepens emotional intelligence and intuition. "
                    "Home, family, and inner peace are highlighted — nurturing your roots brings strength. "
                    "Creative and spiritual activities flourish; trust your instincts above all else."
                ),
                "lucky_number": 2, "lucky_color": "Silver", "lucky_gemstone": "Pearl",
                "career_score": 7.0, "love_score": 8.5, "health_score": 7.5, "finance_score": 6.5,
                "do_today": ["Spend quality time with family", "Practice meditation or journaling"],
                "avoid_today": ["Emotional over-reactions", "Neglecting self-care routines"],
            },
            "Simha": {
                "prediction": (
                    "The Sun illuminates your natural leadership qualities, drawing admiration and opportunities. "
                    "Creative projects and self-expression receive strong cosmic support right now. "
                    "Use your charisma to inspire others; authority figures are receptive to your ideas."
                ),
                "lucky_number": 1, "lucky_color": "Gold", "lucky_gemstone": "Ruby",
                "career_score": 9.0, "love_score": 7.5, "health_score": 8.0, "finance_score": 7.5,
                "do_today": ["Present ideas confidently to decision-makers", "Engage in creative leadership activities"],
                "avoid_today": ["Arrogance or over-confidence", "Dominating conversations unnecessarily"],
            },
            "Kanya": {
                "prediction": (
                    "Mercury bestows analytical clarity and meticulous attention to detail. "
                    "Health and service-oriented activities are favoured — a great time to refine your routines. "
                    "Your practical wisdom and methodical approach help you solve complex problems elegantly."
                ),
                "lucky_number": 5, "lucky_color": "Navy Blue", "lucky_gemstone": "Emerald",
                "career_score": 8.5, "love_score": 6.5, "health_score": 8.5, "finance_score": 7.5,
                "do_today": ["Organise work and health routines", "Review contracts or documents carefully"],
                "avoid_today": ["Over-criticism of self and others", "Excessive worry about minor details"],
            },
            "Tula": {
                "prediction": (
                    "Venus graces Tula with harmony, diplomacy, and aesthetic sensibility. "
                    "Partnerships — business and personal — thrive under balanced Venusian energy. "
                    "Legal matters and negotiations favour you; seek win-win outcomes for lasting results."
                ),
                "lucky_number": 6, "lucky_color": "Pink", "lucky_gemstone": "Diamond",
                "career_score": 7.5, "love_score": 9.0, "health_score": 7.0, "finance_score": 7.5,
                "do_today": ["Strengthen key partnerships", "Engage in artistic or cultural activities"],
                "avoid_today": ["Indecision and prolonged fence-sitting", "Avoiding necessary conflicts"],
            },
            "Vrischika": {
                "prediction": (
                    "Mars intensifies your determination and gives you the power to transform challenges. "
                    "Emotional clarity arrives after deep introspection; trust your powerful instincts. "
                    "Research, hidden resources, and investigative work receive strong cosmic support."
                ),
                "lucky_number": 9, "lucky_color": "Dark Red", "lucky_gemstone": "Red Coral",
                "career_score": 8.0, "love_score": 7.5, "health_score": 7.5, "finance_score": 8.5,
                "do_today": ["Pursue deep research or investigative work", "Release what no longer serves you"],
                "avoid_today": ["Jealousy or possessiveness", "Power struggles in relationships"],
            },
            "Dhanu": {
                "prediction": (
                    "Jupiter, your ruling planet, expands wisdom, optimism, and opportunities for growth. "
                    "Higher education, philosophy, and spiritual pursuits are all favoured under this influence. "
                    "Fortune favours the bold — your natural optimism inspires everyone around you."
                ),
                "lucky_number": 3, "lucky_color": "Yellow", "lucky_gemstone": "Yellow Sapphire",
                "career_score": 8.5, "love_score": 7.5, "health_score": 8.0, "finance_score": 8.0,
                "do_today": ["Pursue learning or higher education goals", "Plan a spiritual journey"],
                "avoid_today": ["Overcommitting to too many projects", "Carelessness with important details"],
            },
            "Makara": {
                "prediction": (
                    "Saturn rewards your discipline and sustained effort with lasting achievements. "
                    "Career advancement and professional recognition are highlighted during this period. "
                    "Long-term investments and structured plans yield excellent returns — patience is your virtue."
                ),
                "lucky_number": 8, "lucky_color": "Black", "lucky_gemstone": "Blue Sapphire",
                "career_score": 9.0, "love_score": 6.0, "health_score": 7.5, "finance_score": 8.5,
                "do_today": ["Focus on long-term career goals", "Review and solidify financial structures"],
                "avoid_today": ["Neglecting relationships for work", "Excessive pessimism or rigidity"],
            },
            "Kumbha": {
                "prediction": (
                    "Saturn and Rahu combine to bring innovation, humanitarian impulses, and unconventional thinking. "
                    "Technology, social causes, and group activities receive strong cosmic support. "
                    "Your visionary ideas can create meaningful, lasting change — embrace the unexpected."
                ),
                "lucky_number": 4, "lucky_color": "Blue", "lucky_gemstone": "Amethyst",
                "career_score": 8.0, "love_score": 7.0, "health_score": 7.0, "finance_score": 7.5,
                "do_today": ["Collaborate on innovative or tech-driven projects", "Engage in community work"],
                "avoid_today": ["Emotional detachment from loved ones", "Rebellion without constructive purpose"],
            },
            "Meena": {
                "prediction": (
                    "Jupiter deepens your spiritual sensitivity, compassion, and creative imagination. "
                    "Artistic, healing, and spiritual vocations flourish under this mystical influence. "
                    "Acts of selfless service attract powerful blessings — your intuition is your greatest guide."
                ),
                "lucky_number": 7, "lucky_color": "Sea Green", "lucky_gemstone": "Yellow Sapphire",
                "career_score": 7.0, "love_score": 8.5, "health_score": 7.0, "finance_score": 6.5,
                "do_today": ["Engage in creative or spiritual practice", "Help someone in need"],
                "avoid_today": ["Escapism or excessive daydreaming", "Setting weak boundaries with others"],
            },
        }
        d = _RASI_DATA.get(sign, _RASI_DATA["Mesha"])
        return {
            "data": {
                "prediction":    d["prediction"],
                "lucky_number":  d["lucky_number"],
                "lucky_color":   d["lucky_color"],
                "lucky_gemstone":d["lucky_gemstone"],
                "career_score":  d["career_score"],
                "love_score":    d["love_score"],
                "health_score":  d["health_score"],
                "finance_score": d["finance_score"],
                "overall_score": round(
                    (d["career_score"] + d["love_score"] + d["health_score"] + d["finance_score"]) / 4, 1
                ),
                "do_today":    d["do_today"],
                "avoid_today": d["avoid_today"],
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
