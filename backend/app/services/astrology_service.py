"""
services/astrology_service.py
Business logic for Kundli, Horoscope, Matchmaking, Muhurtham, AI Chat.
Transforms raw API data into clean response schemas.
"""
import logging
from typing import List

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
        summary = self._parse_summary(kundli_raw)
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
        planets_data = chart.get("data", {}).get("planets", [])
        lagna_rasi = kundli.get("data", {}).get("ascendant", {}).get("rasi", {}).get("name", "Mesha")

        # Build house mapping: lagna is house 1
        rasi_order = ["Mesha","Vrishabha","Mithuna","Karka","Simha","Kanya","Tula","Vrischika","Dhanu","Makara","Kumbha","Meena"]
        try:
            lagna_idx = rasi_order.index(lagna_rasi)
        except ValueError:
            lagna_idx = 0

        result = []
        for p in planets_data:
            name = p.get("name", "")
            rasi = p.get("rasi", {}).get("name", "")
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

    def _parse_summary(self, kundli: dict) -> ChartSummary:
        d = kundli.get("data", {})
        lagna = d.get("ascendant", {}).get("rasi", {}).get("name", "Mesha")
        return ChartSummary(
            lagna=lagna,
            lagna_lord=self._get_rasi_lord(lagna),
            rasi=d.get("rasi", {}).get("name", "Vrischika") if "rasi" in d else "Vrischika",
            rasi_lord=self._get_rasi_lord(d.get("rasi", {}).get("name", "Vrischika") if "rasi" in d else "Vrischika"),
            nakshatra=d.get("nakshatra", {}).get("name", "Aswini"),
            pada=d.get("nakshatra", {}).get("pada", 1),
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
        raw = await self._repo.get_horoscope(sign.value, htype.value)
        d = raw.get("data", {})

        date_ranges = {
            "daily": "Today",
            "weekly": "This Week",
            "monthly": "This Month",
            "yearly": str(__import__("datetime").date.today().year),
        }

        return HoroscopeResponse(
            zodiac_sign=sign.value,
            type=htype.value,
            date_range=date_ranges.get(htype.value, ""),
            overall_score=d.get("overall_score", 7.5),
            scores=CategoryScore(
                career=d.get("career_score", 8.0),
                love=d.get("love_score", 6.5),
                health=d.get("health_score", 7.0),
                finance=d.get("finance_score", 7.0),
            ),
            prediction=d.get("prediction", ""),
            lucky_number=d.get("lucky_number", 7),
            lucky_color=d.get("lucky_color", "Gold"),
            lucky_gemstone=d.get("lucky_gemstone", "Ruby"),
            do_today=["Begin new projects", "Connect with mentors", "Focus on wellness"],
            avoid_today=["Major financial decisions after 4PM", "Arguments with elders"],
        )

    # ── Matchmaking ───────────────────────────────────────────────────────────

    async def get_match(self, req: MatchRequest) -> MatchResponse:
        raw = await self._repo.get_guna_milan(req.person1, req.person2)
        d = raw.get("data", {})

        total = d.get("total_points", 0)
        kutas_raw = d.get("kutas", [])
        has_nadi = d.get("nadi_dosha", False)

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
            ai_analysis=f"With {total}/36 Gunas, this match shows {'excellent' if total >= 28 else 'good'} compatibility. "
                        f"{'The Nadi Dosha requires attention and remedial measures before proceeding.' if has_nadi else 'No major doshas detected.'}"
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
        return MuhurthamResponse(muhurtham_type=req.muhurtham_type.value, slots=slots)
