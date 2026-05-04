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


    def _mock_horoscope(self, sign: str, horo_type: str) -> Dict[str, Any]:  # noqa: C901
        # ── Base data per rasi (shared across all periods) ───────────────────
        _BASE: Dict[str, Any] = {
            "Mesha":     {"lucky_number": 9,  "lucky_color": "Red",       "lucky_gemstone": "Red Coral",
                          "career_score": 8.5, "love_score": 6.5, "health_score": 7.5, "finance_score": 8.0,
                          "do_today":    ["Take initiative on pending projects", "Connect with senior mentors"],
                          "avoid_today": ["Impulsive financial decisions", "Confrontations with authority figures"]},
            "Vrishabha": {"lucky_number": 6,  "lucky_color": "White",     "lucky_gemstone": "Diamond",
                          "career_score": 7.5, "love_score": 8.5, "health_score": 7.0, "finance_score": 8.0,
                          "do_today":    ["Focus on long-term financial planning", "Nurture close relationships"],
                          "avoid_today": ["Stubbornness in negotiations", "Overspending on luxuries"]},
            "Mithuna":   {"lucky_number": 5,  "lucky_color": "Green",     "lucky_gemstone": "Emerald",
                          "career_score": 8.0, "love_score": 7.0, "health_score": 7.5, "finance_score": 7.0,
                          "do_today":    ["Network actively and share ideas", "Read and expand your knowledge"],
                          "avoid_today": ["Scattering energy across too many tasks", "Spreading unverified information"]},
            "Karka":     {"lucky_number": 2,  "lucky_color": "Silver",    "lucky_gemstone": "Pearl",
                          "career_score": 7.0, "love_score": 8.5, "health_score": 7.5, "finance_score": 6.5,
                          "do_today":    ["Spend quality time with family", "Practice meditation or journaling"],
                          "avoid_today": ["Emotional over-reactions", "Neglecting self-care routines"]},
            "Simha":     {"lucky_number": 1,  "lucky_color": "Gold",      "lucky_gemstone": "Ruby",
                          "career_score": 9.0, "love_score": 7.5, "health_score": 8.0, "finance_score": 7.5,
                          "do_today":    ["Present ideas confidently to decision-makers", "Engage in creative leadership"],
                          "avoid_today": ["Arrogance or over-confidence", "Dominating conversations unnecessarily"]},
            "Kanya":     {"lucky_number": 5,  "lucky_color": "Navy Blue", "lucky_gemstone": "Emerald",
                          "career_score": 8.5, "love_score": 6.5, "health_score": 8.5, "finance_score": 7.5,
                          "do_today":    ["Organise work and health routines", "Review contracts carefully"],
                          "avoid_today": ["Over-criticism of self and others", "Excessive worry about minor details"]},
            "Tula":      {"lucky_number": 6,  "lucky_color": "Pink",      "lucky_gemstone": "Diamond",
                          "career_score": 7.5, "love_score": 9.0, "health_score": 7.0, "finance_score": 7.5,
                          "do_today":    ["Strengthen key partnerships", "Engage in artistic or cultural activities"],
                          "avoid_today": ["Indecision and prolonged fence-sitting", "Avoiding necessary conflicts"]},
            "Vrischika": {"lucky_number": 9,  "lucky_color": "Dark Red",  "lucky_gemstone": "Red Coral",
                          "career_score": 8.0, "love_score": 7.5, "health_score": 7.5, "finance_score": 8.5,
                          "do_today":    ["Pursue deep research or investigative work", "Release what no longer serves you"],
                          "avoid_today": ["Jealousy or possessiveness", "Power struggles in relationships"]},
            "Dhanu":     {"lucky_number": 3,  "lucky_color": "Yellow",    "lucky_gemstone": "Yellow Sapphire",
                          "career_score": 8.5, "love_score": 7.5, "health_score": 8.0, "finance_score": 8.0,
                          "do_today":    ["Pursue learning or higher education goals", "Plan a spiritual journey"],
                          "avoid_today": ["Overcommitting to too many projects", "Carelessness with important details"]},
            "Makara":    {"lucky_number": 8,  "lucky_color": "Black",     "lucky_gemstone": "Blue Sapphire",
                          "career_score": 9.0, "love_score": 6.0, "health_score": 7.5, "finance_score": 8.5,
                          "do_today":    ["Focus on long-term career goals", "Review and solidify financial structures"],
                          "avoid_today": ["Neglecting relationships for work", "Excessive pessimism or rigidity"]},
            "Kumbha":    {"lucky_number": 4,  "lucky_color": "Blue",      "lucky_gemstone": "Amethyst",
                          "career_score": 8.0, "love_score": 7.0, "health_score": 7.0, "finance_score": 7.5,
                          "do_today":    ["Collaborate on innovative or tech-driven projects", "Engage in community work"],
                          "avoid_today": ["Emotional detachment from loved ones", "Rebellion without constructive purpose"]},
            "Meena":     {"lucky_number": 7,  "lucky_color": "Sea Green", "lucky_gemstone": "Yellow Sapphire",
                          "career_score": 7.0, "love_score": 8.5, "health_score": 7.0, "finance_score": 6.5,
                          "do_today":    ["Engage in creative or spiritual practice", "Help someone in need"],
                          "avoid_today": ["Escapism or excessive daydreaming", "Setting weak boundaries with others"]},
        }

        # ── Period-specific predictions ───────────────────────────────────────
        _DAILY: Dict[str, str] = {
            "Mesha":     ("Jupiter's beneficial aspect on your 10th house signals professional breakthroughs and public recognition. "
                          "Mars, your ruling planet, grants courage to initiate bold ventures. "
                          "Financial gains come through decisive action — channel your natural energy constructively."),
            "Vrishabha": ("Venus, your ruling planet, showers grace on personal relationships and creative pursuits. "
                          "Financial stability improves as Saturn's steady influence favours disciplined savings. "
                          "Your patience and persistence will yield tangible, lasting results."),
            "Mithuna":   ("Mercury sharpens your intellect and communication skills — ideal for negotiations and new learning. "
                          "Opportunities arise through networking; your versatility is your greatest asset. "
                          "Keep an open mind and explore multiple avenues simultaneously."),
            "Karka":     ("The Moon, your ruling planet, deepens emotional intelligence and intuition. "
                          "Home, family, and inner peace are highlighted — nurturing your roots brings strength. "
                          "Creative and spiritual activities flourish; trust your instincts above all else."),
            "Simha":     ("The Sun illuminates your natural leadership qualities, drawing admiration and opportunities. "
                          "Creative projects and self-expression receive strong cosmic support right now. "
                          "Use your charisma to inspire others; authority figures are receptive to your ideas."),
            "Kanya":     ("Mercury bestows analytical clarity and meticulous attention to detail. "
                          "Health and service-oriented activities are favoured — a great time to refine your routines. "
                          "Your practical wisdom and methodical approach help you solve complex problems elegantly."),
            "Tula":      ("Venus graces Tula with harmony, diplomacy, and aesthetic sensibility. "
                          "Partnerships — business and personal — thrive under balanced Venusian energy. "
                          "Legal matters and negotiations favour you; seek win-win outcomes for lasting results."),
            "Vrischika": ("Mars intensifies your determination and gives you the power to transform challenges. "
                          "Emotional clarity arrives after deep introspection; trust your powerful instincts. "
                          "Research, hidden resources, and investigative work receive strong cosmic support."),
            "Dhanu":     ("Jupiter, your ruling planet, expands wisdom, optimism, and opportunities for growth. "
                          "Higher education, philosophy, and spiritual pursuits are all favoured under this influence. "
                          "Fortune favours the bold — your natural optimism inspires everyone around you."),
            "Makara":    ("Saturn rewards your discipline and sustained effort with lasting achievements. "
                          "Career advancement and professional recognition are highlighted during this period. "
                          "Long-term investments and structured plans yield excellent returns — patience is your virtue."),
            "Kumbha":    ("Saturn and Rahu combine to bring innovation, humanitarian impulses, and unconventional thinking. "
                          "Technology, social causes, and group activities receive strong cosmic support. "
                          "Your visionary ideas can create meaningful, lasting change — embrace the unexpected."),
            "Meena":     ("Jupiter deepens your spiritual sensitivity, compassion, and creative imagination. "
                          "Artistic, healing, and spiritual vocations flourish under this mystical influence. "
                          "Acts of selfless service attract powerful blessings — your intuition is your greatest guide."),
        }

        _WEEKLY: Dict[str, str] = {
            "Mesha": (
                "This week brings a powerful surge of Mars energy across all areas of your life.\n\n"
                "Monday: Strong start — tackle the most important task on your list with full focus. Your drive is at its peak and colleagues take notice.\n\n"
                "Tuesday: A creative solution to a long-standing problem surfaces. Trust your instincts; the bold move pays off. Good day for presentations or pitches.\n\n"
                "Wednesday: Mid-week brings a slight dip in energy. Prioritise rest and avoid heated arguments — Mercury's tension with Mars makes communication sharp-edged.\n\n"
                "Thursday: Jupiter blesses career matters. A senior figure or mentor steps in with valuable guidance. Financial discussions are favourable.\n\n"
                "Friday: Social connections flourish. Networking events or casual conversations lead to meaningful opportunities. Romance is warm and lively.\n\n"
                "Saturday: A good day for physical activity, sports, or outdoor pursuits. Recharge your body and clear your mind.\n\n"
                "Sunday: Reflect and plan. Review progress, set intentions for the week ahead, and spend time with family or close friends."
            ),
            "Vrishabha": (
                "Venus casts a harmonious glow over your week, smoothing relationships and enriching your inner world.\n\n"
                "Monday: Begin the week with financial planning — review investments, bills, or savings goals. Small corrections now yield big dividends later.\n\n"
                "Tuesday: A creative project gains momentum. Aesthetic work — design, art, music, or writing — flows with unusual ease.\n\n"
                "Wednesday: Relationship conversations go well. Express appreciation to loved ones; a simple gesture strengthens bonds significantly.\n\n"
                "Thursday: Career demands attention. A practical opportunity appears — assess it carefully before committing. Patience is your superpower.\n\n"
                "Friday: Social and romantic energies peak. An evening gathering or quiet date night deepens connection and brings joy.\n\n"
                "Saturday: Focus on home and comfort. Redecorate, cook a special meal, or tend your garden — beauty in surroundings lifts your spirit.\n\n"
                "Sunday: Rest deeply. Indulge in self-care rituals. Your body and mind ask for restoration before the week ahead."
            ),
            "Mithuna": (
                "Mercury keeps your mind razor-sharp this week — communication, learning, and connections are your strongest cards.\n\n"
                "Monday: Emails, calls, and meetings go smoothly. Start the week by clearing your inbox and reaching out to contacts you have been meaning to follow up with.\n\n"
                "Tuesday: An unexpected piece of information changes your perspective on an ongoing situation. Stay adaptable — the pivot leads somewhere better.\n\n"
                "Wednesday: Short travel or local movement brings a pleasant surprise. A chance encounter leads to a stimulating conversation and possibly a new opportunity.\n\n"
                "Thursday: Focus on learning — a course, book, podcast, or workshop sharpens your expertise. Knowledge gained now proves useful sooner than expected.\n\n"
                "Friday: Social energy peaks. Host, attend, or organise a gathering. Your wit and charm are magnetic; friendships deepen naturally.\n\n"
                "Saturday: Address pending errands and administrative tasks. Getting organised clears mental clutter and gives you a sense of control.\n\n"
                "Sunday: A quiet, creative Sunday — writing, journaling, or brainstorming new ideas. Your imagination is vivid; capture insights before they fade."
            ),
            "Karka": (
                "The Moon's waxing influence brings emotional depth and family harmony to your week.\n\n"
                "Monday: Begin the week grounded. A conversation with a family member or close friend sets a warm, supportive tone for the days ahead.\n\n"
                "Tuesday: Career intuition is strong — trust your gut on a professional decision. Others may doubt; you are correct in your assessment.\n\n"
                "Wednesday: Emotional sensitivity is heightened mid-week. Avoid overthinking; instead, channel feelings into creative outlets like cooking, art, or music.\n\n"
                "Thursday: Financial matters stabilise. A pending payment arrives or a budget concern resolves more easily than expected.\n\n"
                "Friday: Home life is joyful. A family gathering, celebration, or simply a warm evening in brings deep contentment.\n\n"
                "Saturday: Spiritual or reflective activities nourish your soul. Visit a temple, meditate by water, or spend time in nature.\n\n"
                "Sunday: Rest, cook, and nurture. Prepare for the week ahead by grounding yourself in the comfort of home and the people who matter most."
            ),
            "Simha": (
                "The Sun shines boldly on Simha this week, amplifying your natural charisma and leadership energy.\n\n"
                "Monday: Take charge. A project or team needs direction — step forward with confidence. Your authority is both genuine and inspiring.\n\n"
                "Tuesday: Creative inspiration strikes with force. Art, performance, or a bold idea in the workplace captures everyone's attention.\n\n"
                "Wednesday: A recognition or compliment arrives — receive it graciously. Your reputation continues to grow through consistent excellence.\n\n"
                "Thursday: Financial opportunity presents itself through leadership or visibility. Say yes to the platform or stage offered to you.\n\n"
                "Friday: Romance is electric. Dress your best, plan something memorable, and let your warmth radiate. Existing relationships deepen beautifully.\n\n"
                "Saturday: Physical vitality is high. Exercise, sports, or outdoor activity keeps your energy balanced and your mood elevated.\n\n"
                "Sunday: Reflect on your goals with honesty. Where are you shining brightest? Where is ego clouding your path? Insight arrives in quiet moments."
            ),
            "Kanya": (
                "Mercury bestows extraordinary precision and productivity on Kanya this week — efficiency is your superpower.\n\n"
                "Monday: Begin the week with a detailed plan. Create lists, timelines, and priorities. The groundwork you lay today saves hours later.\n\n"
                "Tuesday: Health check-ins are favoured. Schedule that appointment, start the new routine, or research the wellness approach you have been considering.\n\n"
                "Wednesday: A colleague or co-worker seeks your help. Your expertise resolves a complex problem quickly — your value in the team is evident.\n\n"
                "Thursday: Financial review day — audit subscriptions, track expenses, or refine a budget. Small savings identified now compound meaningfully.\n\n"
                "Friday: Social interactions improve. Let your guard down slightly; not every conversation needs to be perfect. Authenticity disarms and attracts.\n\n"
                "Saturday: Deep-clean, reorganise, or complete a project that has been lingering. Order in your environment brings clarity to your mind.\n\n"
                "Sunday: Recharge through quiet. Read, meditate, or take a gentle walk in nature. Your nervous system benefits greatly from calm and stillness."
            ),
            "Tula": (
                "Venus graces Tula with extraordinary social magnetism and relational harmony this week.\n\n"
                "Monday: A partnership — professional or personal — takes a positive turn. Open dialogue about shared goals creates alignment and excitement.\n\n"
                "Tuesday: Aesthetic projects shine. If you work in design, fashion, beauty, law, or the arts, this is a peak creative day. Collaboration beats solo effort.\n\n"
                "Wednesday: Balance requires attention mid-week. You may feel pulled in two directions — pause, breathe, and choose with deliberate clarity.\n\n"
                "Thursday: Legal or contractual matters move forward. Negotiations you feared may drag resolve with surprising ease and mutual satisfaction.\n\n"
                "Friday: Romance and social life peak. Host a dinner, attend a cultural event, or simply enjoy meaningful conversation over a beautiful meal.\n\n"
                "Saturday: Beautify your space and your self. A new look, a home refresh, or an afternoon at a gallery restores your inner harmony.\n\n"
                "Sunday: Journal, reflect, and assess the week's connections. Which relationships energise you? Which drain you? Calibrate accordingly."
            ),
            "Vrischika": (
                "Intense transformation energy courses through your week — Mars and Pluto demand depth, not surface living.\n\n"
                "Monday: Begin the week with research or investigation. Uncover hidden information relevant to a key decision. Knowledge is power — use it wisely.\n\n"
                "Tuesday: Financial acumen is sharp. A joint resource, inheritance matter, tax question, or investment decision benefits from your focus today.\n\n"
                "Wednesday: Emotional honesty is needed mid-week. A conversation you have been avoiding must happen — it liberates rather than harms.\n\n"
                "Thursday: Power dynamics in professional settings require navigation. Observe quietly before acting; your timing determines everything.\n\n"
                "Friday: Intimacy deepens. Vulnerability creates closeness — let trusted people see your authentic self. Walls come down, connection grows.\n\n"
                "Saturday: Detox — physically and mentally. Release a grudge, skip a toxic habit, cleanse your body, or reorganise a space that felt heavy.\n\n"
                "Sunday: Meditate on transformation. What version of yourself are you becoming? Sit with the discomfort of change; it precedes every breakthrough."
            ),
            "Dhanu": (
                "Jupiter expands your horizons across every dimension this week — think bigger, reach further, and trust the process.\n\n"
                "Monday: The week opens with vision and enthusiasm. Set an ambitious goal and take the first concrete step immediately — momentum is everything.\n\n"
                "Tuesday: Learning accelerates. Enrol in a course, attend a lecture, or dive deep into a subject that excites you. Your mind is a sponge right now.\n\n"
                "Wednesday: Travel or movement of some kind brings a fortunate connection. Even a short trip or change of scenery unlocks new thinking.\n\n"
                "Thursday: Philosophical clarity arrives. A long-held belief is tested; examining it honestly makes you wiser and more compassionate.\n\n"
                "Friday: Social connections with people from different cultures or backgrounds enrich your perspective. Celebrate diversity in your circle.\n\n"
                "Saturday: Outdoor adventure recharges you deeply. Hiking, cycling, or simply sitting under an open sky restores your signature optimism.\n\n"
                "Sunday: Gratitude practice amplifies your luck. Reflect on blessings, acknowledge growth, and approach the new week with an open and grateful heart."
            ),
            "Makara": (
                "Saturn's steady hand guides a week of meaningful progress, professional recognition, and disciplined achievement.\n\n"
                "Monday: Hit the ground running. The most ambitious task on your list is best tackled first; your focus and stamina are at their highest.\n\n"
                "Tuesday: A senior colleague or authority figure offers recognition or a meaningful opportunity. Your consistent effort has not gone unnoticed.\n\n"
                "Wednesday: Mid-week review — assess what is working and what needs adjustment. Your analytical skills identify the bottleneck that has slowed things down.\n\n"
                "Thursday: Financial structures benefit from attention. Review long-term plans, consult an advisor if needed, or make a disciplined investment.\n\n"
                "Friday: Allow yourself to relax. Your tendency to keep working can isolate you from loved ones — make time for warmth, laughter, and connection.\n\n"
                "Saturday: A practical home project or administrative task gets completed efficiently. Satisfaction comes from tangible results.\n\n"
                "Sunday: Plan the week ahead with precision. Set clear priorities, schedule important tasks, and enter Monday with a sense of purpose and readiness."
            ),
            "Kumbha": (
                "Uranus and Saturn combine this week to electrify your innovative thinking and community contributions.\n\n"
                "Monday: A bold idea arrives — do not dismiss it as too unconventional. Your most creative concepts are precisely the ones the world needs.\n\n"
                "Tuesday: Technology or digital tools help you solve a problem efficiently. Explore a new app, platform, or system that streamlines your work.\n\n"
                "Wednesday: Community or group dynamics require your input. Your voice matters in a collective decision — speak with calm conviction.\n\n"
                "Thursday: A humanitarian or social cause calls to you. Even a small action — volunteering, donating, or raising awareness — creates meaningful impact.\n\n"
                "Friday: Friendships take centre stage. A social gathering or online connection brings someone interesting into your orbit. Stay open to unusual people.\n\n"
                "Saturday: Experiment freely — try a new creative process, a different approach to an old problem, or an unconventional experience. Novelty fuels you.\n\n"
                "Sunday: Detach and recharge. Spend time alone in reflection, in nature, or in quiet meditation. Your inner visionary needs silence to hear clearly."
            ),
            "Meena": (
                "Neptune and Jupiter bathe your week in spiritual light, compassionate creativity, and deeply felt intuition.\n\n"
                "Monday: Begin the week in stillness — meditation, prayer, or a few moments of conscious gratitude aligns your inner compass beautifully.\n\n"
                "Tuesday: Creative work flows with unusual grace. Art, music, poetry, or any form of imaginative expression produces something genuinely moving.\n\n"
                "Wednesday: Someone in your circle needs support. Your empathy and presence mean more than any advice — simply listen and hold space.\n\n"
                "Thursday: Spiritual or metaphysical study brings unexpected insights. Astrology, meditation, healing arts, or sacred texts spark genuine revelation.\n\n"
                "Friday: Romance is dreamy and tender. An existing relationship reaches new emotional depth; a new connection feels fated and full of wonder.\n\n"
                "Saturday: Nature is your healer. Spend time near water — a river, lake, beach, or even a long bath. Your body and spirit both need fluidity.\n\n"
                "Sunday: Dream deeply and journal upon waking. Your subconscious is processing profound material; the symbols and feelings carry real guidance."
            ),
        }

        _MONTHLY: Dict[str, str] = {
            "Mesha": (
                "This month, Mars aligns powerfully with Jupiter creating a rare window of career acceleration and personal expansion.\n\n"
                "Career & Finance: The first ten days are ideal for launching new initiatives, negotiating promotions, or pitching bold ideas. A financial opportunity connected to your professional network appears mid-month — evaluate it carefully but act swiftly. The final week consolidates gains; avoid reckless spending and lock in progress made.\n\n"
                "Relationships: Early in the month, passion runs high but so does impatience. Choose your battles wisely — not every argument is worth winning. Around the 15th, a meaningful conversation with a partner, sibling, or close friend brings unexpected clarity and renewed closeness.\n\n"
                "Health & Energy: Your energy levels are excellent through the 20th. Use this period for intense physical training, starting a new fitness routine, or any activity that demands strength and stamina. After the 20th, rest becomes equally important — honour that need without guilt.\n\n"
                "Spiritual Note: The new moon this month falls in a fire sign, igniting your sense of purpose. Set a bold intention and write it down — the cosmos supports manifestation with unusual force this cycle."
            ),
            "Vrishabha": (
                "Venus makes a powerful transit through your sign this month, blessing every area of life with beauty, grace, and material abundance.\n\n"
                "Career & Finance: Your professional image improves dramatically. Dress, speak, and present yourself with extra care — others are watching and are impressed. A financial breakthrough related to property, creative work, or a long-standing investment arrives in the second half of the month.\n\n"
                "Relationships: This is one of the most romantically charged months of the year for Vrishabha. New love connections are possible for singles; established partnerships deepen in warmth and physical affection. Plan something beautiful together — a trip, a meal, or a meaningful shared experience.\n\n"
                "Health & Energy: The body craves pleasure and rest in equal measure. Indulge thoughtfully — nourishing food, massage, gentle yoga, and quality sleep are your best medicines. Avoid excess; moderation keeps your signature vitality high.\n\n"
                "Spiritual Note: The full moon illuminates your 7th house, making partnerships — divine and human — your mirror this month. What are your relationships reflecting back to you? The answer holds your next growth step."
            ),
            "Mithuna": (
                "Mercury, your planetary ruler, is exceptionally strong this month, making your mind your greatest asset across all areas of life.\n\n"
                "Career & Finance: Communication-driven work thrives — writing, speaking, teaching, selling, or negotiating all yield excellent results. A contract or agreement you have been waiting for finally moves forward. Mercury's retrograde earlier in the year is well behind you; clarity and forward motion are now fully restored.\n\n"
                "Relationships: Honest conversations heal. Address anything left unsaid from recent weeks — the planetary support for clear, kind communication is at its strongest. New friendships formed this month through intellectual or creative circles prove lasting and enriching.\n\n"
                "Health & Energy: Nervous energy may accumulate if you overload your schedule. Build in deliberate pauses — even 10 minutes of breathing or walking resets your agile Gemini mind. Your lungs and arms benefit from mindful movement practices.\n\n"
                "Spiritual Note: Your third house is activated, making local travel, writing, and learning your vehicles for spiritual growth this month. A book, podcast, or teacher crosses your path with exactly what you need to hear — pay attention."
            ),
            "Karka": (
                "The Moon moves through multiple phases this month, each bringing a distinct emotional texture to your experience — honour all of them.\n\n"
                "Career & Finance: Home-based work, real estate, family business, or industries connected to care and nourishment all prosper. A financial matter related to property or family assets resolves beneficially in the third week. Trust your intuition in professional decisions — your read of situations is accurate.\n\n"
                "Relationships: Family bonds are a source of both joy and responsibility this month. A family gathering or reunion creates warmth and belonging. In romantic partnerships, emotional honesty — even about fears and vulnerabilities — builds a deeper, more resilient connection.\n\n"
                "Health & Energy: Digestive health and emotional wellbeing are linked for Karka — what and how you eat mirrors how you are feeling inside. Cook nourishing meals, spend time near water, and address emotional stress before it manifests physically.\n\n"
                "Spiritual Note: This month's lunar cycle is particularly sacred for Karka. Observe the new moon and full moon with intention — light a lamp, offer water, or simply sit in moonlight and let the cosmic rhythms flow through you."
            ),
            "Simha": (
                "The Sun, your ruling planet, blazes through your sector of creativity and recognition this month — this is your season to shine without apology.\n\n"
                "Career & Finance: Leadership opportunities multiply. You are seen, celebrated, and sought out for your vision and confidence. A promotion, award, public acknowledgement, or significant creative win arrives for many Simha natives this month. Financially, bold moves made with clear strategy succeed.\n\n"
                "Relationships: Your warmth and generosity make you irresistible this month. Romantic connections sizzle with passion and play. For those in committed partnerships, shared joy — travel, celebration, or creative projects together — strengthens the bond beautifully.\n\n"
                "Health & Energy: Vitality is at a yearly high for much of this month. Lean into physical pursuits — dance, sport, vigorous exercise — that let you express your leonine energy. Heart health and spine wellbeing benefit from consistent movement and good posture.\n\n"
                "Spiritual Note: Your 5th house — the house of joy, creativity, and children — is fully illuminated. Whatever brings your soul alive this month is not indulgence; it is a sacred practice. Let joy be your devotion."
            ),
            "Kanya": (
                "Mercury directs precise, analytical energy into every area of your life this month, helping you achieve mastery through attention and method.\n\n"
                "Career & Finance: This is your month to shine professionally through expertise and reliability. A project you have been quietly perfecting receives appreciation and tangible reward. Financial organisation pays off — debts cleared, systems refined, and investments reviewed bring measurable peace of mind.\n\n"
                "Relationships: You may be tempted to over-analyse a relationship situation instead of simply being present. Practice feeling rather than thinking with loved ones. A health-conscious activity shared with a partner — cooking, hiking, yoga — deepens your connection in unexpected ways.\n\n"
                "Health & Energy: Your 6th house of health is highlighted — this is the ideal month to start a new wellness protocol, address a nagging symptom, or consult a specialist. Digestion, nutrition, and daily routine respond excellently to mindful adjustment.\n\n"
                "Spiritual Note: Service is your spiritual path, and this month it bears extraordinary fruit. Volunteer, mentor, or simply offer your skill where it is most needed. The universe returns your investment of time and care with precision and generosity."
            ),
            "Tula": (
                "Venus, your planetary ruler, graces your relationship sector with exceptional harmony, beauty, and balanced abundance this month.\n\n"
                "Career & Finance: Collaborations flourish — joint ventures, partnerships, and team-based work all outperform solo efforts. A creative or aesthetic project wins praise and material reward. Financial matters connected to partnerships or contracts move in your favour in the final third of the month.\n\n"
                "Relationships: This is one of the most important romantic months of your year. Singles may meet someone significant through a social, cultural, or professional setting. Committed couples reach a new level of intimacy and mutual understanding. Communication is elegant and genuine — say what your heart means.\n\n"
                "Health & Energy: Kidneys, lower back, and skin are your focus areas this month. Stay hydrated, move your body gently and consistently, and reduce sugar intake for glowing results. Beauty rituals are not vanity for Tula — they are self-respect.\n\n"
                "Spiritual Note: Balance is your dharma and your deepest spiritual teaching. Where in your life are you overgiving or undervaluing yourself? The scales of Tula ask for honest recalibration — in relationships, in work, and in how you treat yourself."
            ),
            "Vrischika": (
                "Mars, your ruling planet, moves through a powerful sector of transformation and shared resources this month — depth is your gift and your journey.\n\n"
                "Career & Finance: Research, investigation, strategic work, and high-stakes decisions all benefit from your focus this month. A financial matter involving shared assets, inheritance, taxation, or investment requires careful attention — but resolves strongly in your favour with diligent effort.\n\n"
                "Relationships: Intimacy — emotional and physical — deepens significantly this month. Trust is both tested and proven. A relationship that survives a difficult conversation this month becomes unshakeable. Let your guard down with those who have earned it; the vulnerability creates lasting bonds.\n\n"
                "Health & Energy: Reproductive health, detox pathways, and emotional processing are your key focus areas. Support your body with clean eating, adequate water, and regular movement. Therapy, journaling, or energy healing work profoundly this month.\n\n"
                "Spiritual Note: Transformation is your soul's work, and this month accelerates it. What must die so that something greater can be born? Embrace the ending with trust — Vrischika always rises from the ashes with new power and clarity."
            ),
            "Dhanu": (
                "Jupiter, your ruling planet and the greatest benefic in Vedic astrology, showers this month with expansion, opportunity, and inspired optimism.\n\n"
                "Career & Finance: Doors open with unusual ease. A job offer, business expansion, educational opportunity, or travel-related development changes your trajectory positively. Say yes to the expansive option — Dhanu is built for growth, not contraction. Financial abundance follows courage and faith.\n\n"
                "Relationships: Your natural enthusiasm and warmth make you magnetic this month. New connections from different cultures, belief systems, or life backgrounds bring rich perspective and genuine companionship. Existing relationships benefit from shared adventure — plan a trip, explore a new cuisine, or attend an inspiring event together.\n\n"
                "Health & Energy: Your hips, thighs, and liver benefit from movement and moderation. Avoid excess in food and activity — your zest for life can tip into overindulgence. Outdoor exercise in open spaces recharges you far more than indoor routines.\n\n"
                "Spiritual Note: A pilgrimage — physical or metaphorical — awaits you this month. Whether you visit a sacred site, begin a new philosophical study, or commit to a daily spiritual practice, the universe meets your seeking with revelation and grace."
            ),
            "Makara": (
                "Saturn, your ruling planet, continues its deep rewiring of your sense of purpose, authority, and long-term legacy this month.\n\n"
                "Career & Finance: This is a month of significant professional advancement. A position of greater authority, a complex responsibility, or a formal recognition of your expertise arrives for many Makara natives. Financially, disciplined long-term decisions made now have extraordinary compounding effects — think in decades, not days.\n\n"
                "Relationships: Your tendency to prioritise work over relationships is challenged this month. A loved one needs your presence — not your productivity. Making time for warmth and vulnerability strengthens the most important bonds in your life. Quality time outweighs grand gestures.\n\n"
                "Health & Energy: Bones, joints, teeth, and skin are Makara's health domains — give them attention this month. Regular strength training, calcium-rich nutrition, adequate vitamin D, and disciplined sleep schedules protect your long-term physical foundation.\n\n"
                "Spiritual Note: Your dharma this month is mastery through humility. True authority does not demand; it earns. Where can you lead with more patience and compassion? The answer is where your greatest legacy is being forged."
            ),
            "Kumbha": (
                "Uranus and Saturn create an electrifying field of innovation and community purpose around you this month — you are a force for meaningful change.\n\n"
                "Career & Finance: Technology, futurism, social enterprise, and group-driven projects excel. An unusual or unconventional career development opens a door you did not know existed. Financially, a network connection or collective investment opportunity rewards those who look beyond conventional options.\n\n"
                "Relationships: Friendships and community bonds deepen in ways that feel genuinely chosen rather than circumstantial. A group activity — club, cause, creative collective, or online community — brings your people to you. In romantic life, intellectual compatibility and shared values are more important to you than chemistry alone.\n\n"
                "Health & Energy: Circulation, ankles, and nervous system are your monthly focus areas. Regular movement, breathwork, and limiting overstimulation (screens, news, social media) protect your unique energetic sensitivity. Meditation and sound healing are particularly effective for Kumbha this month.\n\n"
                "Spiritual Note: You are here to carry a vision the world is not yet ready for — and this month asks you to carry it anyway. Your highest spiritual act is to remain true to your revolutionary inner knowing without seeking approval for it."
            ),
            "Meena": (
                "Jupiter and Neptune conspire to make this one of the most spiritually potent months of your year — the veils between worlds are thin, and your intuition is flawless.\n\n"
                "Career & Finance: Creative, healing, spiritual, or service-oriented work flourishes this month. Your compassion and imagination are not soft skills — they are your greatest competitive advantages. A financial matter tied to creative work, a legacy gift, or a generous benefactor improves your situation in the latter half of the month.\n\n"
                "Relationships: Love this month is profound, tender, and almost otherworldly in its resonance. A new romantic connection may feel fated; an existing partnership reaches a new depth of soul recognition. Guard your boundaries, however — your empathy can absorb others' pain as though it is your own.\n\n"
                "Health & Energy: Feet, lymphatic system, and immune health are your monthly focus areas. Aquatic exercise, adequate sleep, clean nutrition, and time in nature are your best medicines. Watch for a tendency to neglect your own needs while serving others — reciprocity matters.\n\n"
                "Spiritual Note: This month, the dream world communicates with unusual clarity. Keep a dream journal, pay attention to synchronicities, and trust the guidance that arrives in moments of stillness. You are receiving exactly what you need — the invitation is simply to listen."
            ),
        }

        _YEARLY: Dict[str, str] = {
            "Mesha": (
                "2026 is a defining year for Mesha — Mars and Jupiter form a rare alliance that amplifies ambition, courage, and transformative professional momentum.\n\n"
                "Career & Purpose: The first quarter of the year opens a powerful window for career reinvention, launching ventures, or claiming leadership roles you have been preparing for. Your natural pioneering energy is fully supported by planetary forces — fear of failure gives way to bold, decisive action. Significant recognition arrives for many Mesha natives between April and July.\n\n"
                "Finance & Abundance: Financial gains are tied directly to your courage and initiative this year. Those who act boldly are rewarded; those who hesitate miss the window. Real estate, business expansion, and performance-based income all show strong potential. Build emergency reserves in Q3 as Saturn creates a brief period of financial caution.\n\n"
                "Relationships & Love: The middle of the year brings a significant romantic development — a new love connection, a deepening of commitment, or a resolution of long-standing relationship tension. Family dynamics shift positively as Jupiter blesses your 4th house from June onward.\n\n"
                "Health & Vitality: Your energy is exceptional in the first and third quarters. Use these windows for intense physical goals. The second quarter calls for recovery and restoration — listen to your body's signals and do not push through fatigue.\n\n"
                "Spiritual Theme: This year, Mesha is asked to lead with wisdom rather than simply with power. The universe is developing your capacity for compassionate authority — the kind that transforms situations without domination. Your spiritual growth lies at the intersection of action and discernment."
            ),
            "Vrishabha": (
                "2026 is a year of beautiful consolidation and material flowering for Vrishabha — the seeds of discipline sown in recent years now bear visible, tangible fruit.\n\n"
                "Career & Purpose: Venus's transit through favourable houses brings aesthetic recognition and professional elevation, particularly for those in creative, financial, culinary, luxury, or relationship-oriented fields. A significant career achievement — promotion, award, business milestone, or creative breakthrough — arrives between March and August for most Vrishabha natives.\n\n"
                "Finance & Abundance: This is one of your strongest financial years in nearly a decade. Property investments, creative monetisation, and long-term saving strategies all yield excellent returns. Venus's influence makes beauty literally profitable — your taste and aesthetic judgment are a genuine asset this year.\n\n"
                "Relationships & Love: Love deepens, stabilises, and evolves into something more enduring and nourishing. Married couples invest in shared experiences that become treasured memories. Singles seeking commitment encounter serious, genuine partners in the second half of the year.\n\n"
                "Health & Vitality: Focus on throat health, thyroid function, and nutritional quality throughout the year. Your body thrives on rhythm and routine — irregular eating and sleeping schedules are your greatest health risk. Gentle, consistent movement outperforms intense, sporadic exercise.\n\n"
                "Spiritual Theme: Your spiritual growth this year comes through beauty, sensory experience, and deep appreciation of the material world as sacred. Gratitude is your highest practice — not as a performance, but as a genuine recognition that abundance surrounds you at every level."
            ),
            "Mithuna": (
                "2026 activates Mithuna's intellectual gifts with extraordinary force — communication, learning, and adaptability are your defining themes across all four quarters.\n\n"
                "Career & Purpose: Writing, speaking, education, media, technology, sales, and any communication-driven field sees exceptional growth. A platform opportunity — a book, podcast, YouTube channel, course, or public-speaking role — elevates your visibility and influence significantly. Mercury's favourable transits in Q2 and Q4 mark your peak professional windows.\n\n"
                "Finance & Abundance: Multiple income streams develop naturally this year — your diverse skills are finally being monetised simultaneously. A short-term trading or income opportunity in Q1 should be taken with clear eyes and an exit strategy. Long-term financial planning benefits enormously from professional advice in Q3.\n\n"
                "Relationships & Love: A sibling, neighbour, or childhood connection plays a significant role in your relational landscape this year. In romantic life, intellectual chemistry and playful communication are the foundations of your best connections. Those who bore you lose your attention; those who challenge and stimulate you capture your heart.\n\n"
                "Health & Vitality: Respiratory health, nervous system regulation, and shoulder/arm wellbeing are your annual focus areas. Breathwork, regular outdoor walks, and digital detox periods protect your uniquely wired Gemini nervous system from overstimulation.\n\n"
                "Spiritual Theme: Your spiritual path this year is through curiosity itself. Every question you ask sincerely is a form of prayer. Every new perspective you genuinely consider is an act of devotion. The universe rewards your openness with revelations that arrive as conversations, books, and chance encounters."
            ),
            "Karka": (
                "2026 is a deeply significant year of inner transformation and outer anchoring for Karka — your roots deepen while your branches reach further than ever before.\n\n"
                "Career & Purpose: Home-based work, remote leadership, real estate, hospitality, food, childcare, and any field connected to nurturing or comfort see outstanding results. A change of role, relocation, or significant home-related professional development reshapes your daily life positively. Your emotional intelligence becomes a formal professional asset this year.\n\n"
                "Finance & Abundance: Property matters resolve very favourably for most Karka natives in 2026. A family financial matter that has been complex and unresolved finally closes with clarity and benefit. Build a financial safety net in Q2 — your instinct that a change is coming is correct; preparation turns disruption into opportunity.\n\n"
                "Relationships & Love: Family is your greatest source of both joy and growth this year. A birth, marriage, reunion, or healing of an old family wound transforms your sense of belonging. In romantic life, emotional security and domestic harmony are what you both need and offer — a deeply nourishing love story unfolds for many Karka natives in Q3 and Q4.\n\n"
                "Health & Vitality: Digestive health, chest and breast wellbeing, and emotional processing are your year-long focus areas. The body-emotion connection is particularly strong for Karka — addressing suppressed feelings consistently pays enormous physical dividends.\n\n"
                "Spiritual Theme: Home is your temple and family is your sangha this year. The mundane acts of cooking, nurturing, and creating safety for others are your highest spiritual practice. The divine is in the ordinary for Karka in 2026."
            ),
            "Simha": (
                "2026 places Simha squarely in the spotlight — the Sun and Jupiter conspire to make this a year of extraordinary creative flourishing, leadership recognition, and personal radiance.\n\n"
                "Career & Purpose: This is your signature year for professional ascension. Leadership roles, creative direction, entrepreneurship, performance, and any field where personality and vision matter see exceptional outcomes. The recognition you have been working toward — quietly or loudly — arrives in earnest between May and September. Do not shrink from visibility; this is your moment.\n\n"
                "Finance & Abundance: Financial gains through creative work, investments in personal branding, and entrepreneurial ventures are highlighted all year. Q1 rewards bold financial action; Q3 is ideal for locking in gains and making structured long-term investments. Generosity in Q4 creates extraordinary karmic returns.\n\n"
                "Relationships & Love: Your warmth, humour, and magnetic presence attract deeply compatible partners this year. Romantic life blossoms with passion and playfulness. Existing relationships are reinvigorated by shared adventures, creative collaborations, or a bold romantic gesture that reminds both of you why you chose each other.\n\n"
                "Health & Vitality: Heart health, spine strength, and vitality are your annual focus areas. Cardiovascular exercise, posture awareness, and managing the stress that comes with high-visibility roles protect your long-term wellbeing. Joy is literally good medicine for Simha — prioritise it without guilt.\n\n"
                "Spiritual Theme: This year asks Simha to explore the difference between ego and soul expression. Your light is real — the work is to let it shine without needing validation. True radiance comes from giving freely rather than performing for applause."
            ),
            "Kanya": (
                "2026 is a year of exceptional mastery and professional precision for Kanya — your attention to detail, analytical depth, and service ethic are rewarded in ways that finally match your actual contribution.\n\n"
                "Career & Purpose: Health, science, technology, analysis, writing, editing, finance, and service-oriented fields all produce outstanding results. A project you have been refining for months reaches completion and receives the recognition it deserves. Mercury's strong transits in Q1 and Q3 mark your most productive professional windows — use them with full focus.\n\n"
                "Finance & Abundance: Methodical financial habits produce measurable wealth growth this year. Debt reduction, investment diversification, and eliminating wasteful expenditure create a satisfying sense of financial control and security. An unexpected financial benefit — a refund, settlement, or income increase — arrives in Q2.\n\n"
                "Relationships & Love: Relationships deepen through shared daily life and practical care rather than grand gestures. A health journey shared with a partner — cooking together, exercising together, or supporting each other through a wellness goal — strengthens your bond in ways that romance alone cannot. Singles meet genuine partners through work or health-related settings.\n\n"
                "Health & Vitality: Digestive health, gut microbiome, and nervous system regulation are your year-long priorities. A specific health protocol started in Q1 produces measurable improvements by Q3. Trust the data your body provides — your analytical mind is its best advocate.\n\n"
                "Spiritual Theme: Perfection is not the goal — wholeness is. Your spiritual growth in 2026 lies in accepting your own imperfection with the same compassion you effortlessly extend to others. Self-forgiveness is your most transformative practice this year."
            ),
            "Tula": (
                "2026 places relationships — of every kind — at the very centre of Tula's experience, making this a profoundly connective, harmonising, and love-rich year.\n\n"
                "Career & Purpose: Partnerships, collaborative ventures, diplomacy, legal work, the arts, fashion, and any role where your ability to bring people together is valued all flourish dramatically. A significant professional partnership forms or deepens in Q2. Your reputation for fairness and elegance becomes your most valuable professional currency.\n\n"
                "Finance & Abundance: Joint finances — shared investments, business partnerships, or combined household economics — improve significantly this year. A legal or contractual matter that has been slow-moving resolves in your favour in Q3. Venus's transits through your finance houses in Q1 and Q4 create two peak windows for financial decision-making.\n\n"
                "Relationships & Love: This is arguably the most romantically significant year for Tula in nearly a decade. A deeply compatible, enduring love connection either begins or transforms profoundly. Committed partnerships reach new levels of mutual appreciation and shared vision. The love you experience this year reminds you what genuine partnership truly feels like.\n\n"
                "Health & Vitality: Kidneys, hormonal balance, lower back health, and skin all benefit from conscious attention throughout 2026. Regular hydration, reduced sugar intake, gentle movement, and adequate rest keep your natural elegance and vitality at their peak.\n\n"
                "Spiritual Theme: Your deepest spiritual teaching in 2026 is through the mirror of relationship. Every significant person in your life this year is showing you something essential about yourself. The question to sit with: what are your most important relationships asking you to become?"
            ),
            "Vrischika": (
                "2026 is a year of deep, irreversible transformation for Vrischika — the kind that does not merely change your circumstances but fundamentally reshapes who you are.\n\n"
                "Career & Purpose: Research, psychology, strategy, finance, investigation, healing, and any field that requires going beneath the surface all see exceptional results. A hidden opportunity — one not visible to casual observers — reveals itself to your discerning gaze between March and June. Your ability to see what others miss becomes the source of your greatest professional advantage.\n\n"
                "Finance & Abundance: Shared resources, investments, inheritance matters, insurance claims, or partnership finances shift significantly and beneficially in 2026. Q2 requires financial caution and careful documentation; Q4 brings a meaningful resolution. Your financial intuition is unusually sharp this year — trust it, but verify with data.\n\n"
                "Relationships & Love: Deep emotional bonds are formed, tested, or renewed in 2026. A relationship that survives the intensity of this year's truths becomes unbreakable. Intimacy — genuine, unguarded vulnerability — is both what you crave and what you offer this year. Those who cannot meet you at that depth naturally fall away.\n\n"
                "Health & Vitality: Reproductive health, detoxification pathways, and emotional wellbeing are interconnected priorities throughout 2026. Regular cleansing protocols, emotional processing through therapy or journaling, and adequate rest support the profound internal reorganisation your body and psyche are undergoing.\n\n"
                "Spiritual Theme: Death and rebirth are Vrischika's eternal themes — and 2026 enacts them at every level simultaneously. What you release this year creates space for something of extraordinary power and beauty. Trust the dissolution; it is always purposeful."
            ),
            "Dhanu": (
                "2026 is one of the most expansive, fortunate, and horizon-broadening years Dhanu has experienced in a full Jupiter cycle — the universe is genuinely conspiring in your favour.\n\n"
                "Career & Purpose: Education, publishing, international business, law, philosophy, travel, media, and any field connected to the transmission of wisdom and the crossing of borders all produce remarkable results. A teaching, speaking, or thought-leadership opportunity in Q2 or Q3 significantly elevates your reach and reputation. Fortune consistently rewards your boldness and optimism this year.\n\n"
                "Finance & Abundance: Financial growth is steady and multi-faceted in 2026. An international income stream, educational investment that pays returns, or expansion of an existing business into new markets all show strong potential. Your natural risk-tolerance, balanced by Jupiter's wisdom, leads you to the right opportunities at the right moments.\n\n"
                "Relationships & Love: Love this year carries the energy of adventure, intellectual kinship, and shared philosophy. A relationship that challenges your worldview while delighting your spirit is the most meaningful connection available to you. Travel with a partner — even locally — deepens bonds and creates memories that sustain the relationship through any difficulty.\n\n"
                "Health & Vitality: Liver health, hip flexibility, and sciatic nerve wellness are your annual focus areas. Outdoor movement, varied physical activity, and avoiding dietary excess protect your robust constitution. Your optimism is genuinely medicinal — maintain it consciously by limiting exposure to negativity.\n\n"
                "Spiritual Theme: 2026 is your year of the teacher becoming the student again. The universe assigns you a wisdom tradition, teacher, or philosophical framework that permanently enriches your inner life. Approach every encounter this year as a potential initiation — something sacred is being transmitted."
            ),
            "Makara": (
                "2026 is the culmination year of a multi-year Saturn cycle that has been refining, testing, and ultimately fortifying every dimension of Makara's character and outer life.\n\n"
                "Career & Purpose: The sustained effort of recent years crystallises into measurable, durable achievement in 2026. A position of significant authority, a formal recognition of expertise, or a business reaching a meaningful scale milestone marks this year as historically significant in your professional biography. Your reputation for reliability and excellence opens doors that talent alone cannot.\n\n"
                "Finance & Abundance: Long-term financial structures — retirement planning, real estate, structured investments, or business equity — show the most significant gains in 2026. Q1 and Q3 are your peak windows for major financial decisions. Saturn rewards patience and punishes shortcuts — your disciplined approach is finally, definitively vindicated.\n\n"
                "Relationships & Love: This year, the personal cost of professional ambition becomes clear. Those who have waited patiently for your presence deserve and receive it in 2026. A relationship either deepens through renewed attention and genuine partnership or clarifies that it has served its purpose. Either outcome is ultimately a gift.\n\n"
                "Health & Vitality: Skeletal health, dental wellbeing, joint flexibility, and skin condition are your year-long priorities. A structured wellness protocol — consistent sleep, disciplined nutrition, regular strength training, and annual health screenings — protects the physical foundation of all your achievements.\n\n"
                "Spiritual Theme: Your deepest spiritual work in 2026 is accepting that worthiness does not have to be earned. You have spent lifetimes proving yourself through discipline and achievement. This year, the universe invites you to rest in inherent value — to understand that you deserve abundance not because of what you have built, but simply because you exist."
            ),
            "Kumbha": (
                "2026 is a year of revolutionary self-expression and collective contribution for Kumbha — your vision for a better future finds both voice and vehicle this year.\n\n"
                "Career & Purpose: Technology, innovation, social enterprise, humanitarian work, digital media, science, and any field on the frontier of what is possible all see extraordinary breakthroughs. An unconventional career path that seemed impractical suddenly reveals itself as both viable and deeply meaningful. Your unique perspective is your competitive moat — lean into it completely.\n\n"
                "Finance & Abundance: Collaborative income models — group ventures, community-funded projects, platform-based earnings, or cooperative investments — outperform solo financial strategies in 2026. An unexpected windfall or sudden financial opportunity arrives in Q2; evaluate it quickly but thoroughly. Network relationships prove financially generative throughout the year.\n\n"
                "Relationships & Love: Chosen family — the friends, communities, and kindred spirits who see and celebrate your authentic self — are the primary source of love and belonging in 2026. Romantic connections that honour your need for independence while providing genuine emotional safety are the only ones that satisfy. Those who try to confine or conventionalise you lose your interest quickly.\n\n"
                "Health & Vitality: Circulatory health, ankle strength, and nervous system regulation are your annual priorities. Regular aerobic movement, breathwork, time in community rather than isolation, and deliberate digital detox periods protect your unique energetic sensitivity and creative output.\n\n"
                "Spiritual Theme: You are a channel for the future — and 2026 asks you to take that responsibility seriously. Your most sacred act this year is to live the vision you carry, however unconventional it appears. The world will eventually catch up. Your task is simply to lead by authentic example."
            ),
            "Meena": (
                "2026 is a year of sacred completion, spiritual culmination, and compassionate wisdom for Meena — the closing of a great cycle and the quiet dawn of the next.\n\n"
                "Career & Purpose: Creative arts, healing modalities, spiritual teaching, humanitarian work, cinema, music, poetry, psychology, and any field that requires both imagination and empathy flourish powerfully in 2026. A creative work or healing practice reaches a significant milestone — it is seen, felt, and valued by exactly the right people at the right time.\n\n"
                "Finance & Abundance: A financial matter connected to the past — an old debt resolved, a creative project finally monetised, or an inheritance or gift received — brings unexpected material comfort in Q2 or Q3. Your financial intuition is unusually accurate this year; trust the inner signals you receive about when to act and when to wait.\n\n"
                "Relationships & Love: Love this year is transcendent, compassionate, and soul-deep. A romantic connection formed in 2026 carries a sense of karmic recognition — as though you have known this person across time. Existing partnerships reach new heights of spiritual intimacy and unconditional acceptance. Your capacity to love without condition is your greatest gift and your most sacred spiritual achievement.\n\n"
                "Health & Vitality: Feet, lymphatic system, immune function, and sleep quality are your year-long health priorities. Aquatic exercise, adequate uninterrupted sleep, clean nutrition, and consistent time in nature protect both your physical vitality and your empathic sensitivity. Guard carefully against absorbing others' emotional pain as your own.\n\n"
                "Spiritual Theme: 2026 is a year of dissolution and surrender for Meena — the highest spiritual practice your sign knows. The ego's carefully constructed identity softens, and something vast, compassionate, and eternal takes its place. You do not lose yourself in this surrender; you find, finally, your truest self."
            ),
        }

        # ── Assemble response ─────────────────────────────────────────────────
        b = _BASE.get(sign, _BASE["Mesha"])

        if horo_type == "weekly":
            prediction = _WEEKLY.get(sign, _WEEKLY["Mesha"])
        elif horo_type == "monthly":
            prediction = _MONTHLY.get(sign, _MONTHLY["Mesha"])
        elif horo_type == "yearly":
            prediction = _YEARLY.get(sign, _YEARLY["Mesha"])
        else:
            prediction = _DAILY.get(sign, _DAILY["Mesha"])

        return {
            "data": {
                "prediction":     prediction,
                "lucky_number":   b["lucky_number"],
                "lucky_color":    b["lucky_color"],
                "lucky_gemstone": b["lucky_gemstone"],
                "career_score":   b["career_score"],
                "love_score":     b["love_score"],
                "health_score":   b["health_score"],
                "finance_score":  b["finance_score"],
                "overall_score":  round(
                    (b["career_score"] + b["love_score"] +
                     b["health_score"] + b["finance_score"]) / 4, 1
                ),
                "do_today":    b["do_today"],
                "avoid_today": b["avoid_today"],
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
