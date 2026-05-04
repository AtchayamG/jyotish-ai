"""
services/astrology_service.py
Business logic for Kundli, Horoscope, Matchmaking, Muhurtham, AI Chat.
Transforms raw API data into clean response schemas.
"""
import logging
from typing import List

from app.core.http_client import http_client
from app.repositories.astrology_repository import AstrologyRepository
from app.schemas.astrology_schema import (
    BirthDetails,
    CategoryScore,
    ChartSummary,
    DashaEntry,
    DoshaInfo,
    HoroscopeResponse,
    HoroscopeType,
    KundliResponse,
    KutaScore,
    MatchRequest,
    MatchResponse,
    MuhurthamRequest,
    MuhurthamResponse,
    MuhurthamSlot,
    PlanetPosition,
    ZodiacSign,
)

logger = logging.getLogger(__name__)

# ── English zodiac → Sanskrit rasi mapper (Prokerala returns English) ─────────
_EN_TO_RASI = {
    "Aries":       "Mesha",
    "Taurus":      "Vrishabha",
    "Gemini":      "Mithuna",
    "Cancer":      "Karka",
    "Leo":         "Simha",
    "Virgo":       "Kanya",
    "Libra":       "Tula",
    "Scorpio":     "Vrischika",
    "Sagittarius": "Dhanu",
    "Capricorn":   "Makara",
    "Aquarius":    "Kumbha",
    "Pisces":      "Meena",
}

def _to_rasi(name: str) -> str:
    """Convert English zodiac name to Sanskrit rasi. Passthrough if already Sanskrit."""
    return _EN_TO_RASI.get(name, name)

# Planet exaltation/debilitation mapping
_PLANET_STATUS = {
    "Sun":     {"exalted": "Mesha", "debilitated": "Tula", "own": ["Simha"]},
    "Moon":    {"exalted": "Vrishabha", "debilitated": "Vrischika", "own": ["Karka"]},
    "Mars":    {"exalted": "Makara", "debilitated": "Karka", "own": ["Mesha", "Vrischika"]},
    "Mercury": {"exalted": "Kanya", "debilitated": "Meena", "own": ["Mithuna", "Kanya"]},
    "Venus":   {"exalted": "Meena", "debilitated": "Kanya", "own": ["Vrishabha", "Tula"]},
    "Jupiter": {"exalted": "Karka", "debilitated": "Makara", "own": ["Dhanu", "Meena"]},
    "Saturn":  {"exalted": "Tula", "debilitated": "Mesha", "own": ["Makara", "Kumbha"]},
    "Rahu":    {"exalted": "Mithuna", "debilitated": "Dhanu", "own": []},
    "Ketu":    {"exalted": "Dhanu", "debilitated": "Mithuna", "own": []},
}

_PLANET_SYMBOLS = {
    "Sun": "☉", "Moon": "☽", "Mars": "♂", "Mercury": "☿",
    "Venus": "♀", "Jupiter": "♃", "Saturn": "♄",
    "Rahu": "☊", "Ketu": "☋",
}

_KUTA_DESCRIPTIONS = {
    "Varna": "Spiritual compatibility and ego level match",
    "Vashya": "Mutual attraction and dominance factor",
    "Tara": "Birth star compatibility and health prospects",
    "Yoni": "Sexual compatibility and physical harmony",
    "Graha Maitri": "Mental compatibility and friendship between lords",
    "Gana": "Temperament and behaviour compatibility",
    "Bhakoot": "Emotional compatibility and financial prosperity",
    "Nadi": "Health, progeny and genetic compatibility",
}


def _planet_status(planet_name: str, rasi: str) -> str:
    info = _PLANET_STATUS.get(planet_name, {})
    if rasi == info.get("exalted"):
        return "Exalted"
    if rasi == info.get("debilitated"):
        return "Debilitated"
    if rasi in info.get("own", []):
        return "Own Sign"
    return "Neutral"


def _degree_to_str(longitude: float) -> str:
    deg = int(longitude % 30)
    minutes = int((longitude % 1) * 60)
    return f"{deg:02d}°{minutes:02d}'"


def _score_to_verdict(score: int) -> str:
    if score >= 28:
        return "Excellent Match — Highly Recommended"
    if score >= 21:
        return "Good Match — Recommended"
    if score >= 18:
        return "Average Match — Acceptable"
    return "Poor Match — Not Recommended"


class AstrologyService:
    def __init__(self, repo: AstrologyRepository) -> None:
        self._repo = repo

    # ── Kundli ────────────────────────────────────────────────────────────────

    async def get_kundli(self, birth: BirthDetails) -> KundliResponse:
        chart_raw, kundli_raw = await self._repo.get_birth_chart(birth), await self._repo.get_kundli_chart(birth)

        planets = self._parse_planets(chart_raw, kundli_raw)
        summary = self._parse_summary(kundli_raw, chart_raw)
        dashas = self._mock_dashas(kundli_raw)

        current = kundli_raw.get("data", {})
        current_dasha = f"{current.get('current_mahadasha','?')}–{current.get('current_antardasha','?')}"

        return KundliResponse(
            birth_details=birth,
            summary=summary,
            planets=planets,
            current_dasha=current_dasha,
            dashas=dashas,
            ai_insight=self._generate_kundli_insight(planets, summary),
        )

    def _parse_planets(self, chart: dict, kundli: dict) -> List[PlanetPosition]:
        # Prokerala uses 'planet_position'; mock data uses 'planets'
        planets_data = (
            chart.get("data", {}).get("planet_position")
            or chart.get("data", {}).get("planets", [])
        )
        # Prokerala: ascendant.name (English); mock: ascendant.rasi.name (Sanskrit)
        lagna_raw = (
            kundli.get("data", {}).get("ascendant", {}).get("name")
            or kundli.get("data", {}).get("ascendant", {}).get("rasi", {}).get("name", "Aries")
        )
        lagna_rasi = _to_rasi(lagna_raw)

        # Build house mapping: lagna is house 1
        rasi_order = ["Mesha","Vrishabha","Mithuna","Karka","Simha","Kanya","Tula","Vrischika","Dhanu","Makara","Kumbha","Meena"]
        try:
            lagna_idx = rasi_order.index(lagna_rasi)
        except ValueError:
            lagna_idx = 0

        result = []
        for p in planets_data:
            name = p.get("name", "")
            # Prokerala returns English names; convert to Sanskrit
            rasi = _to_rasi(p.get("rasi", {}).get("name", ""))
            longitude = p.get("longitude", 0.0)
            nakshatra = p.get("nakshatra", {}).get("name", "")
            pada = p.get("nakshatra_pada", 1)
            is_retro = p.get("is_retrograde", False)

            try:
                rasi_idx = rasi_order.index(rasi)
                house = ((rasi_idx - lagna_idx) % 12) + 1
            except ValueError:
                house = 1

            result.append(PlanetPosition(
                name=name,
                symbol=_PLANET_SYMBOLS.get(name, "●"),
                rasi=rasi,
                degree=_degree_to_str(longitude),
                nakshatra=nakshatra,
                pada=pada,
                house=house,
                is_retrograde=is_retro,
                status=_planet_status(name, rasi),
            ))
        return result

    def _parse_summary(self, kundli: dict, chart: dict = None) -> ChartSummary:
        d = kundli.get("data", {})

        # Lagna: Prokerala → ascendant.name (English); mock → ascendant.rasi.name (Sanskrit)
        lagna_raw = (
            d.get("ascendant", {}).get("name")
            or d.get("ascendant", {}).get("rasi", {}).get("name", "Aries")
        )
        lagna = _to_rasi(lagna_raw)

        # Rasi (Moon sign): try multiple sources in priority order
        # 1. Prokerala kundli: moon_sign.name (English)
        # 2. Moon planet in planet_position (English) or planets (Sanskrit)
        # 3. Kundli top-level rasi key (mock legacy)
        # 4. Default fallback
        rasi = None
        moon_sign_raw = d.get("moon_sign", {}).get("name") if "moon_sign" in d else None
        if moon_sign_raw:
            rasi = _to_rasi(moon_sign_raw)

        if not rasi and chart:
            chart_data = chart.get("data", {})
            planet_list = (
                chart_data.get("planet_position")
                or chart_data.get("planets", [])
            )
            for p in planet_list:
                if p.get("name", "").lower() == "moon":
                    rasi = _to_rasi(p.get("rasi", {}).get("name", ""))
                    break

        if not rasi:
            rasi = _to_rasi(d.get("rasi", {}).get("name", "Vrischika") if "rasi" in d else "Vrischika")

        # Nakshatra: Prokerala uses English; nakshatras tend to be Sanskrit-consistent
        nakshatra = d.get("nakshatra", {}).get("name", "Aswini")
        pada      = d.get("nakshatra", {}).get("pada", 1)

        return ChartSummary(
            lagna=lagna,
            lagna_lord=self._get_rasi_lord(lagna),
            rasi=rasi,
            rasi_lord=self._get_rasi_lord(rasi),
            nakshatra=nakshatra,
            pada=pada,
            tithi=d.get("tithi", {}).get("name", "Ekadashi"),
            yoga=d.get("yoga", {}).get("name", "Siddhi"),
            karana=d.get("karana", {}).get("name", "Bava"),
            ayana="Uttarayana",
        )

    def _get_rasi_lord(self, rasi: str) -> str:
        lords = {
            "Mesha": "Mars", "Vrishabha": "Venus", "Mithuna": "Mercury",
            "Karka": "Moon", "Simha": "Sun", "Kanya": "Mercury",
            "Tula": "Venus", "Vrischika": "Mars", "Dhanu": "Jupiter",
            "Makara": "Saturn", "Kumbha": "Saturn", "Meena": "Jupiter",
        }
        return lords.get(rasi, "Unknown")

    def _mock_dashas(self, kundli: dict) -> List[DashaEntry]:
        return [
            DashaEntry(planet="Rahu", start_date="2018-06-01", end_date="2036-06-01", is_current=True,
                antardasha=[
                    DashaEntry(planet="Venus", start_date="2024-01-01", end_date="2026-09-01", is_current=True),
                    DashaEntry(planet="Sun", start_date="2026-09-01", end_date="2027-09-01", is_current=False),
                ]),
            DashaEntry(planet="Jupiter", start_date="2036-06-01", end_date="2052-06-01", is_current=False),
            DashaEntry(planet="Saturn", start_date="2052-06-01", end_date="2071-06-01", is_current=False),
        ]

    def _generate_kundli_insight(self, planets: List[PlanetPosition], summary: ChartSummary) -> str:
        exalted = [p.name for p in planets if p.status == "Exalted"]
        debilitated = [p.name for p in planets if p.status == "Debilitated"]
        insight = f"Your Lagna is {summary.lagna}, ruled by {summary.lagna_lord}. "
        if exalted:
            insight += f"Exalted planets ({', '.join(exalted)}) indicate strong karmic blessings. "
        if debilitated:
            insight += f"Debilitated planets ({', '.join(debilitated)}) call for specific remedies to balance their energy. "
        return insight.strip()

    # ── Horoscope ─────────────────────────────────────────────────────────────

    async def get_horoscope(self, sign: ZodiacSign, htype: HoroscopeType, language: str) -> HoroscopeResponse:
        import datetime
        date_ranges = {
            "daily":   "Today",
            "weekly":  "This Week",
            "monthly": "This Month",
            "yearly":  str(datetime.date.today().year),
        }

        # 1. Try Prokerala
        raw = await self._repo.get_horoscope(sign.value, htype.value)
        d = raw.get("data", {})
        if d.get("prediction"):
            return HoroscopeResponse(
                zodiac_sign=sign.value, type=htype.value,
                date_range=date_ranges.get(htype.value, ""),
                overall_score=d.get("overall_score", 7.5),
                scores=CategoryScore(
                    career=d.get("career_score", 8.0), love=d.get("love_score", 6.5),
                    health=d.get("health_score", 7.0), finance=d.get("finance_score", 7.0),
                ),
                prediction=d["prediction"],
                lucky_number=d.get("lucky_number", 7),
                lucky_color=d.get("lucky_color", "Gold"),
                lucky_gemstone=d.get("lucky_gemstone", "Ruby"),
                do_today=d.get("do_today", []),
                avoid_today=d.get("avoid_today", []),
            )

        # 2. AI-generated horoscope (primary path when Prokerala is unavailable)
        ai_data = await self._ai_horoscope(sign.value, htype.value)
        if ai_data:
            return HoroscopeResponse(
                zodiac_sign=sign.value, type=htype.value,
                date_range=date_ranges.get(htype.value, ""),
                overall_score=ai_data.get("overall_score", 7.5),
                scores=CategoryScore(
                    career=ai_data.get("career_score", 8.0),
                    love=ai_data.get("love_score", 6.5),
                    health=ai_data.get("health_score", 7.0),
                    finance=ai_data.get("finance_score", 7.0),
                ),
                prediction=ai_data.get("prediction", ""),
                lucky_number=int(ai_data.get("lucky_number", 7)),
                lucky_color=ai_data.get("lucky_color", "Gold"),
                lucky_gemstone=ai_data.get("lucky_gemstone", "Ruby"),
                do_today=ai_data.get("do_today", []),
                avoid_today=ai_data.get("avoid_today", []),
            )

        # 3. Static fallback (only if both above fail)
        fallback = self._repo._mock_horoscope(sign.value, htype.value).get("data", {})
        return HoroscopeResponse(
            zodiac_sign=sign.value, type=htype.value,
            date_range=date_ranges.get(htype.value, ""),
            overall_score=fallback.get("overall_score", 7.5),
            scores=CategoryScore(
                career=fallback.get("career_score", 8.0), love=fallback.get("love_score", 6.5),
                health=fallback.get("health_score", 7.0), finance=fallback.get("finance_score", 7.0),
            ),
            prediction=fallback.get("prediction", ""),
            lucky_number=fallback.get("lucky_number", 7),
            lucky_color=fallback.get("lucky_color", "Gold"),
            lucky_gemstone=fallback.get("lucky_gemstone", "Ruby"),
            do_today=["Meditate at sunrise", "Review long-term goals"],
            avoid_today=["Unnecessary arguments", "Hasty financial decisions"],
        )

    async def _ai_horoscope(self, sign: str, htype: str) -> dict:
        """Generate horoscope via OpenAI when Prokerala is unavailable."""
        from app.core.config import settings
        if not settings.OPENAI_API_KEY:
            return {}

        import json, datetime
        today = datetime.date.today().strftime("%d %B %Y")
        period_map = {"daily": f"day of {today}", "weekly": "current week",
                      "monthly": "current month", "yearly": "current year"}
        period = period_map.get(htype, f"day of {today}")

        prompt = (
            f"Generate a Vedic astrology horoscope for {sign} rasi for the {period}. "
            f"Base it on Vedic/Jyotish principles. Be specific and insightful (3-4 sentences). "
            f"Return ONLY valid JSON with exactly these keys: "
            f"prediction (string), career_score (float 1-10), love_score (float 1-10), "
            f"health_score (float 1-10), finance_score (float 1-10), overall_score (float 1-10), "
            f"lucky_number (int), lucky_color (string), lucky_gemstone (string), "
            f"do_today (list of 2 strings), avoid_today (list of 2 strings)."
        )

        try:
            resp = await http_client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {settings.OPENAI_API_KEY}",
                    "Content-Type":  "application/json",
                },
                json={
                    "model":           settings.OPENAI_MODEL,
                    "messages":        [{"role": "user", "content": prompt}],
                    "max_tokens":      400,
                    "temperature":     0.7,
                    "response_format": {"type": "json_object"},
                },
            )
            content = resp.get("choices", [{}])[0].get("message", {}).get("content", "")
            return json.loads(content) if content else {}
        except Exception as exc:
            logger.warning(f"[AstroSvc] AI horoscope failed: {exc}")
            return {}

    # ── Matchmaking ───────────────────────────────────────────────────────────

    async def get_match(self, req: MatchRequest) -> MatchResponse:
        # 1. Compute birth charts for both persons
        from app.services.astro_compute import compute_chart

        def _chart(b):
            r = compute_chart(b.year, b.month, b.day, b.hour, b.minute,
                              b.latitude, b.longitude, b.timezone)
            planets = r.get("chart", {}).get("data", {}).get("planet_position", [])
            moon = next((p for p in planets if p["name"] == "Moon"), {})
            rasi = moon.get("rasi", {}).get("name", "Mesha")
            nak  = moon.get("nakshatra", {}).get("name", "Aswini")
            return rasi, nak

        boy_rasi,  boy_nak  = _chart(req.person1)
        girl_rasi, girl_nak = _chart(req.person2)

        # 2. Run Ashtakoota algorithm
        from app.services.astro_match import compute_ashtakoota
        raw = compute_ashtakoota(boy_rasi, boy_nak, girl_rasi, girl_nak)
        d = raw.get("data", {})

        total     = d.get("total_points", 0)
        kutas_raw = d.get("kutas", [])
        has_nadi  = d.get("nadi_dosha", False)

        kuta_scores = [
            KutaScore(
                name=k["name"],
                max_score=k["total"],
                obtained_score=k["obtained"],
                description=_KUTA_DESCRIPTIONS.get(k["name"], ""),
            )
            for k in kutas_raw
        ]

        dosha = DoshaInfo(
            has_dosha=has_nadi,
            dosha_type="Nadi Dosha" if has_nadi else None,
            severity="moderate" if has_nadi else None,
            remedy="Perform Nadi Dosha Parihara puja at a Shiva temple. Consult an expert astrologer." if has_nadi else None,
        )

        return MatchResponse(
            total_score=total,
            percentage=round((total / 36) * 100, 1),
            verdict=_score_to_verdict(total),
            kuta_scores=kuta_scores,
            dosha=dosha,
            ai_analysis=(
                f"Ashtakoota score: {total}/36 ({round((total/36)*100)}%). "
                f"Boy's Moon: {boy_rasi} ({boy_nak}). "
                f"Girl's Moon: {girl_rasi} ({girl_nak}). "
                + ("The Nadi Dosha requires attention and remedial measures before proceeding."
                   if has_nadi else "No major doshas detected.")
            )
        )

    # ── Muhurtham ─────────────────────────────────────────────────────────────

    async def get_muhurtham(self, req: MuhurthamRequest) -> MuhurthamResponse:
        raw = await self._repo.get_muhurtham(
            req.muhurtham_type.value,
            req.from_date,
            req.to_date,
            req.latitude,
            req.longitude,
        )
        slots_raw = raw.get("data", {}).get("muhurthas", [])
        if slots_raw:
            slots = [
                MuhurthamSlot(
                    date=s["date"],
                    start_time=s["start"],
                    end_time=s["end"],
                    quality=s["quality"],
                    nakshatra=s["nakshatra"],
                    tithi=s["tithi"],
                )
                for s in slots_raw
            ]
        else:
            # Compute real auspicious slots using Swiss Ephemeris
            slots = self._compute_muhurtham_slots(
                req.from_date, req.to_date,
                req.latitude, req.longitude,
            )
        return MuhurthamResponse(muhurtham_type=req.muhurtham_type.value, slots=slots)

    def _compute_muhurtham_slots(
        self,
        from_date: str,
        to_date: str,
        lat: float,
        lng: float,
    ) -> list:
        """
        Compute auspicious muhurtham slots using Swiss Ephemeris.
        Identifies days with favourable nakshatras (Rohini, Hasta, Pushya,
        Shravana, Mrigashira, Revati) and good tithi (not 4,8,14,Amavasya).
        Returns up to 5 slots between from_date and to_date.
        """
        import datetime
        try:
            import swisseph as swe
            swe.set_sid_mode(swe.SIDM_LAHIRI)
        except ImportError:
            return self._dynamic_mock_slots(from_date, to_date)

        GOOD_NAK = {3, 7, 12, 21, 4, 26}  # Rohini, Pushya, Hasta, Shravana, Mrigashira, Revati
        BAD_TITHI = {4, 8, 14, 15, 29, 30}  # Chaturthi, Ashtami, Chaturdashi, Amavasya, Purnima

        _NAK_NAMES = [
            "Aswini","Bharani","Krittika","Rohini","Mrigashira","Ardra",
            "Punarvasu","Pushya","Ashlesha","Magha","Purva Phalguni",
            "Uttara Phalguni","Hasta","Chitra","Swati","Vishakha",
            "Anuradha","Jyeshtha","Mula","Purva Ashadha","Uttara Ashadha",
            "Shravana","Dhanishtha","Shatabhisha","Purva Bhadrapada",
            "Uttara Bhadrapada","Revati",
        ]

        def parse_date(s: str):
            return datetime.date.fromisoformat(s)

        start = parse_date(from_date)
        end   = parse_date(to_date)
        slots = []
        day = start

        while day <= end and len(slots) < 5:
            # Compute Moon position at 06:00 local on this day
            jd = swe.julday(day.year, day.month, day.day, 6.0 - 5.5)  # IST offset
            moon_res, _ = swe.calc_ut(jd, swe.MOON, swe.FLG_SIDEREAL)
            moon_lon = moon_res[0]

            nak_idx  = int(moon_lon / (360 / 27)) % 27
            nak_name = _NAK_NAMES[nak_idx]

            # Tithi: 12° per tithi
            sun_res, _ = swe.calc_ut(jd, swe.SUN, swe.FLG_SIDEREAL)
            sun_lon   = sun_res[0]
            tithi     = int(((moon_lon - sun_lon) % 360) / 12) + 1
            tithi_names = [
                "Pratipada","Dwitiya","Tritiya","Chaturthi","Panchami",
                "Shashthi","Saptami","Ashtami","Navami","Dashami",
                "Ekadashi","Dwadashi","Trayodashi","Chaturdashi","Purnima",
                "Pratipada","Dwitiya","Tritiya","Chaturthi","Panchami",
                "Shashthi","Saptami","Ashtami","Navami","Dashami",
                "Ekadashi","Dwadashi","Trayodashi","Chaturdashi","Amavasya",
            ]
            tithi_name = tithi_names[(tithi - 1) % 30]

            if nak_idx in GOOD_NAK and tithi not in BAD_TITHI:
                quality = "Excellent" if nak_idx in {3, 7, 12} else "Good"
                slots.append(MuhurthamSlot(
                    date=day.isoformat(),
                    start_time="07:00",
                    end_time="09:30",
                    quality=quality,
                    nakshatra=nak_name,
                    tithi=tithi_name,
                ))

            day += datetime.timedelta(days=1)

        return slots if slots else self._dynamic_mock_slots(from_date, to_date)

    def _dynamic_mock_slots(self, from_date: str, to_date: str) -> list:
        """Fallback: return 3 dynamic slots spaced from from_date."""
        import datetime
        start = datetime.date.fromisoformat(from_date)
        naks = ["Rohini", "Hasta", "Pushya"]
        tithis = ["Tritiya", "Panchami", "Saptami"]
        return [
            MuhurthamSlot(
                date=(start + datetime.timedelta(days=i * 5)).isoformat(),
                start_time="07:23",
                end_time="09:47",
                quality="Good",
                nakshatra=naks[i],
                tithi=tithis[i],
            )
            for i in range(3)
        ]
