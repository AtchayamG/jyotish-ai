"""
services/ai_chat_service.py
Jyotish AI chatbot powered by OpenAI GPT-4o-mini.
Falls back to rule-based responses when OPENAI_API_KEY is not set.

Set in Render env vars:
  OPENAI_API_KEY = your_openai_key
  OPENAI_MODEL   = gpt-4o-mini  (default — cost efficient)
"""
import logging
import math
import datetime
from typing import List, Optional, Tuple

from app.core.config import settings
from app.core.http_client import http_client
from app.schemas.astrology_schema import AIChatRequest, AIChatResponse, BirthDetails, ChatMessage

logger = logging.getLogger(__name__)

# ── Vimshottari dasha tables ──────────────────────────────────────────────────

_DASHA_SEQUENCE = [
    ("Ketu",    7),
    ("Venus",   20),
    ("Sun",     6),
    ("Moon",    10),
    ("Mars",    7),
    ("Rahu",    18),
    ("Jupiter", 16),
    ("Saturn",  19),
    ("Mercury", 17),
]

_NAK_TO_DASHA = [
    "Ketu", "Venus", "Sun", "Moon", "Mars", "Rahu", "Jupiter", "Saturn", "Mercury",   # 0-8
    "Ketu", "Venus", "Sun", "Moon", "Mars", "Rahu", "Jupiter", "Saturn", "Mercury",   # 9-17
    "Ketu", "Venus", "Sun", "Moon", "Mars", "Rahu", "Jupiter", "Saturn", "Mercury",   # 18-26
]

_DASHA_YEARS = dict(_DASHA_SEQUENCE)


def _compute_current_dasha(
    moon_longitude: float,
    birth_year: int, birth_month: int, birth_day: int,
) -> Tuple[str, str]:
    """
    Compute Vimshottari mahadasha and antardasha for the given birth date.
    Returns (mahadasha_str, antardasha_str) as human-readable strings with dates.
    """
    nak_span = 360.0 / 27.0           # 13.333...° per nakshatra
    nak_idx  = int(moon_longitude / nak_span) % 27
    frac_in_nak = (moon_longitude % nak_span) / nak_span   # 0..1

    # The planet whose nakshatra the Moon is in starts the dasha
    start_planet = _NAK_TO_DASHA[nak_idx]
    start_years  = _DASHA_YEARS[start_planet]

    # Fraction already elapsed at birth
    elapsed_years = frac_in_nak * start_years
    # Balance remaining in first dasha at birth
    balance_years = start_years - elapsed_years

    # Find index of start_planet in sequence
    seq_planets = [p for p, _ in _DASHA_SEQUENCE]
    start_idx = seq_planets.index(start_planet)

    # Build timeline: (planet, start_date, end_date)
    birth_dt = datetime.date(birth_year, birth_month, birth_day)

    def add_years(d: datetime.date, y: float) -> datetime.date:
        """Add fractional years to a date."""
        days = int(y * 365.25)
        return d + datetime.timedelta(days=days)

    today = datetime.date.today()
    cursor = birth_dt
    current_maha = None
    maha_end     = None

    for i in range(9):
        idx = (start_idx + i) % 9
        planet, years = _DASHA_SEQUENCE[idx]
        period_years = balance_years if i == 0 else years
        end = add_years(cursor, period_years)

        if cursor <= today < end or (i == 8 and today >= cursor):
            current_maha = planet
            maha_end     = end
            maha_start   = cursor

            # ── Antardasha within this maha ──────────────────────────────────
            total_maha_days = (maha_end - maha_start).days or 1
            antar_cursor = maha_start
            current_antar = None
            antar_end    = None

            for j in range(9):
                antar_idx = (seq_planets.index(planet) + j) % 9
                antar_planet, antar_years = _DASHA_SEQUENCE[antar_idx]
                # Antardasha duration proportional to its share of 120 years
                antar_days = int(total_maha_days * antar_years / 120.0)
                antar_end_dt = antar_cursor + datetime.timedelta(days=antar_days)

                if antar_cursor <= today < antar_end_dt or j == 8:
                    current_antar = antar_planet
                    antar_end = antar_end_dt
                    break
                antar_cursor = antar_end_dt

            antar_str = (
                f"{current_antar} Antardasha (until {antar_end.strftime('%b %Y')})"
                if current_antar and antar_end else f"{planet} Antardasha"
            )
            maha_str = (
                f"{planet} Mahadasha (until {maha_end.strftime('%b %Y')})"
                if maha_end else f"{planet} Mahadasha"
            )
            return maha_str, antar_str

        cursor = end

    return "Rahu Mahadasha", "Venus Antardasha"


def _compute_kundli_context(birth: BirthDetails) -> str:
    """
    Compute full Vedic birth chart using Swiss Ephemeris and return a rich
    text block suitable for injection into the AI system prompt.
    Returns empty string if pyswisseph is not installed.
    """
    try:
        from app.services.astro_compute import compute_chart
    except ImportError:
        return ""

    try:
        result = compute_chart(
            year=birth.year, month=birth.month, day=birth.day,
            hour=birth.hour, minute=birth.minute,
            latitude=birth.latitude, longitude=birth.longitude,
            timezone=birth.timezone,
        )
    except Exception as e:
        logger.warning(f"[ChatSvc] astro_compute failed: {e}")
        return ""

    if not result:
        return ""

    kundli_data = result.get("kundli", {}).get("data", {})
    chart_data  = result.get("chart",  {}).get("data", {})

    lagna     = kundli_data.get("ascendant", {}).get("name", "Unknown")
    moon_sign = kundli_data.get("moon_sign", {}).get("name", "Unknown")
    nakshatra = kundli_data.get("nakshatra", {}).get("name", "Unknown")
    pada      = kundli_data.get("nakshatra", {}).get("pada", 1)

    planets = chart_data.get("planet_position", [])

    # Planet summary lines
    planet_lines = []
    moon_lon = 0.0
    for p in planets:
        name  = p.get("name", "")
        rasi  = p.get("rasi", {}).get("name", "")
        nak   = p.get("nakshatra", {}).get("name", "")
        retro = " (Retrograde)" if p.get("is_retrograde") else ""
        planet_lines.append(f"  {name}: {rasi}, {nak}{retro}")
        if name == "Moon":
            moon_lon = p.get("longitude", 0.0)

    # Vimshottari dasha
    try:
        maha_str, antar_str = _compute_current_dasha(
            moon_lon, birth.year, birth.month, birth.day
        )
    except Exception:
        maha_str, antar_str = "Unknown Mahadasha", "Unknown Antardasha"

    tz_str = f"UTC+{birth.timezone}" if birth.timezone >= 0 else f"UTC{birth.timezone}"
    lines = [
        "",
        "=== USER'S BIRTH CHART (Swiss Ephemeris · Lahiri Ayanamsa) ===",
        f"Name          : {birth.name}",
        f"Date of Birth : {birth.day:02d}/{birth.month:02d}/{birth.year}",
        f"Time of Birth : {birth.hour:02d}:{birth.minute:02d} {tz_str}",
        f"Coordinates   : {birth.latitude:.4f}°N, {birth.longitude:.4f}°E",
        "",
        f"Lagna (Ascendant) : {lagna}",
        f"Rasi  (Moon Sign) : {moon_sign}",
        f"Janma Nakshatra   : {nakshatra}, Pada {pada}",
        "",
        f"Current Mahadasha  : {maha_str}",
        f"Current Antardasha : {antar_str}",
        "",
        "Planetary Positions:",
    ] + planet_lines + [
        "=== END OF BIRTH CHART ===",
        "",
        "CRITICAL: ALL your answers MUST reference the above chart data.",
        "When asked 'what is my lagna' answer with the Lagna above.",
        "When asked about dasha answer with the Current Mahadasha/Antardasha above.",
        "Never say you don't know the user's chart — the complete chart is above.",
    ]

    return "\n".join(lines)


# ── System prompt ─────────────────────────────────────────────────────────────
_SYSTEM_PROMPT = """You are Jyotish AI, a deeply knowledgeable personal Vedic and Tamil astrologer. You have mastery of:
- Parasara, KP, and Nadi Jyotish systems
- Brihat Parashara Hora Shastra and classical texts
- Tamil Jyotish (Tamizh Jothidam) and Nadi leaf reading
- Muhurtham (auspicious timing) calculations
- Gemstone remedies, mantras, rituals, Vastu Shastra
- Nakshatra characteristics, Dasha periods, transits

CRITICAL RULES — follow these strictly:
1. You are a PERSONAL astrologer for THIS specific user. ALL answers must be based ONLY on their birth chart provided below.
2. Do NOT give generic universal predictions. Every response must reference the user's specific Lagna, Rasi, Nakshatra, or Dasha period from their chart.
3. If the user asks "what is my lagna / rasi / nakshatra / dasha", answer DIRECTLY using the chart data provided — never say you don't know.
4. If no birth chart is attached below, ask the user to complete their profile for personalised readings.
5. Frame predictions as "indications" and "planetary influences" — never absolute certainties.
6. If user writes in Tamil, respond fully in Tamil script.
7. Keep responses concise (2–3 paragraphs) unless deep analysis is requested.
8. End with 1–2 follow-up question suggestions on a new line starting with "Suggestions:"
9. Be respectful of all spiritual traditions.
10. NEVER give cookie-cutter generic responses — every answer must feel unique to this person's specific chart."""

_SUGGESTIONS = [
    ["What does my current dasha indicate?", "Which gemstone should I wear?"],
    ["When will my career improve?", "What remedies help my situation?"],
    ["Tell me about my marriage prospects", "What are today's auspicious times?"],
    ["Explain my lagna's characteristics", "How can I strengthen Jupiter in my chart?"],
    ["What does my nakshatra reveal?", "Which houses are strongest in my chart?"],
]
_sug_idx = 0


class AIChatService:

    async def chat(self, req: AIChatRequest) -> AIChatResponse:
        # Pre-compute kundli context once — used in both OpenAI and rule-based paths
        chart_context = ""
        if req.user_birth_details:
            chart_context = _compute_kundli_context(req.user_birth_details)

        if not settings.OPENAI_API_KEY:
            logger.info("[ChatSvc] No OpenAI key — using rule-based fallback")
            return self._rule_based(req.message, req.user_birth_details, chart_context)

        try:
            return await self._openai(req, chart_context)
        except Exception as e:
            logger.error(f"[ChatSvc] OpenAI error: {e} — falling back to rules")
            return self._rule_based(req.message, req.user_birth_details, chart_context)

    async def _openai(self, req: AIChatRequest, chart_context: str) -> AIChatResponse:
        # Build system message with injected chart
        system = _SYSTEM_PROMPT + chart_context

        # Build message history (last 10 turns max to control token cost)
        messages = [{"role": "system", "content": system}]
        for h in req.history[-10:]:
            messages.append({"role": h.role, "content": h.content})
        messages.append({"role": "user", "content": req.message})

        resp = await http_client.post(
            "https://api.openai.com/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {settings.OPENAI_API_KEY}",
                "Content-Type":  "application/json",
            },
            json={
                "model":       settings.OPENAI_MODEL,
                "messages":    messages,
                "max_tokens":  800,
                "temperature": 0.75,
            },
        )

        full_reply = resp["choices"][0]["message"]["content"].strip()

        # Parse suggestions if model included them
        suggestions: List[str] = []
        if "Suggestions:" in full_reply:
            parts = full_reply.split("Suggestions:", 1)
            full_reply = parts[0].strip()
            raw_sugs = parts[1].strip().split("\n")
            suggestions = [s.strip().lstrip("•-1234567890. ") for s in raw_sugs if s.strip()][:3]

        if not suggestions:
            global _sug_idx
            suggestions = _SUGGESTIONS[_sug_idx % len(_SUGGESTIONS)]
            _sug_idx += 1

        return AIChatResponse(reply=full_reply, suggested_questions=suggestions)

    def _rule_based(
        self,
        message: str,
        birth: Optional[BirthDetails],
        chart_context: str,
    ) -> AIChatResponse:
        global _sug_idx
        msg = message.lower()

        # ── Extract chart facts if available ─────────────────────────────────
        lagna       = "your Lagna"
        rasi        = "your Moon sign"
        nakshatra   = "your Nakshatra"
        name        = "Seeker"
        maha_str    = "your current Mahadasha"
        antar_str   = "your current Antardasha"

        if birth:
            name = birth.name.split()[0] if birth.name else "Seeker"
            # Parse chart_context lines for quick lookup
            for line in chart_context.splitlines():
                if "Lagna (Ascendant)" in line:
                    lagna = line.split(":", 1)[-1].strip()
                elif "Rasi  (Moon Sign)" in line:
                    rasi = line.split(":", 1)[-1].strip()
                elif "Janma Nakshatra" in line:
                    nakshatra = line.split(":", 1)[-1].strip()
                elif "Current Mahadasha" in line and "Antardasha" not in line:
                    maha_str = line.split(":", 1)[-1].strip()
                elif "Current Antardasha" in line:
                    antar_str = line.split(":", 1)[-1].strip()

        # ── Pattern matching ──────────────────────────────────────────────────

        if any(w in msg for w in ["lagna", "ascendant", "rising"]):
            reply = (
                f"Namaskaram, {name}! Your Lagna (Ascendant) is **{lagna}**. "
                f"This is the sign rising on the eastern horizon at the moment of your birth and "
                f"shapes your personality, physical appearance, and overall life path. "
                f"The lord of {lagna} is particularly significant in your chart — its placement "
                f"determines the strength of your Lagna and how its qualities manifest in your life.\n\n"
                f"As a {lagna} Lagna native, you carry distinct characteristics associated with this rasi. "
                f"Your current {maha_str} further colours how these Lagna traits express themselves during this period. "
                f"Would you like a deeper analysis of your Lagna's strengths and weaknesses?"
            )

        elif any(w in msg for w in ["rasi", "moon sign", "moon rasi", "rashi"]):
            reply = (
                f"Your Rasi (Moon Sign) is **{rasi}**, {name}. "
                f"The Moon sign in Vedic astrology reveals your emotional nature, subconscious mind, "
                f"and how you process feelings. It is equally important as the Lagna in Jyotish.\n\n"
                f"Your Moon in {rasi} indicates a particular emotional temperament and inner world. "
                f"Combined with your {nakshatra} Nakshatra, this gives a nuanced picture of your mental "
                f"and emotional patterns. During the current {maha_str}, your Moon sign's qualities "
                f"are especially prominent — the Mahadasha lord and Moon interact to shape your experiences."
            )

        elif any(w in msg for w in ["nakshatra", "birth star", "star", "janma"]):
            reply = (
                f"Your Janma Nakshatra (birth star) is **{nakshatra}**, {name}. "
                f"This is the lunar mansion the Moon was occupying at the moment of your birth. "
                f"In Vedic astrology, the Nakshatra reveals your deepest karmic patterns, innate "
                f"talents, and the subtle qualities of your mind.\n\n"
                f"Your {nakshatra} Nakshatra has a specific deity, planetary ruler, and symbol "
                f"that all carry meaning for your journey. The current {maha_str} interacts with "
                f"your Nakshatra lord to create the themes you're experiencing now. "
                f"Chanting the Nakshatra mantra associated with {nakshatra} can strengthen its positive influence."
            )

        elif any(w in msg for w in ["dasha", "mahadasha", "antardasha", "period", "vimsottari", "vimshottari"]):
            reply = (
                f"Your current period is the **{maha_str}** with **{antar_str}**, {name}.\n\n"
                f"In Vimshottari Dasha — the primary timing system in Vedic astrology — the Mahadasha planet "
                f"governs the overarching themes of your life during its period. The Antardasha planet "
                f"acts as a sub-influence, shaping day-to-day experiences within that broader framework.\n\n"
                f"The interaction between these two planets — their natural significations, house placements "
                f"in your chart, and mutual relationship — determines the quality of results. "
                f"Propitiating the Mahadasha lord through mantra, gems, or charitable acts can help "
                f"smooth its influence during challenging phases."
            )

        elif any(w in msg for w in ["marry", "marriage", "wedding", "vivah", "kalyanam", "partner"]):
            reply = (
                f"For marriage timing, {name}, your 7th house and its lord in the {lagna} chart are key. "
                f"Venus, the natural karaka for relationships, and the 7th house lord's Mahadasha/Antardasha "
                f"periods are the primary windows for significant romantic developments.\n\n"
                f"Your current {maha_str} ({antar_str}) provides the immediate timing context. "
                f"Transit of Jupiter over the 7th house or natal Venus also activates relationship themes. "
                f"A Navamsa (D9) chart analysis alongside your current dasha gives the most precise timing.\n\n"
                f"Remedy: Chant 'Om Shukraya Namah' 108 times on Fridays and offer white flowers "
                f"to the Goddess to invoke Venus's blessings for a harmonious partnership. 🙏"
            )

        elif any(w in msg for w in ["career", "job", "work", "profession", "business", "thozhil"]):
            reply = (
                f"Career matters for a {lagna} Lagna native like you, {name}, are governed primarily "
                f"by the 10th house and its lord, along with the planet Saturn (Karma karaka).\n\n"
                f"Your current {maha_str} ({antar_str}) is the key timing factor for career developments now. "
                f"This dasha planet's relationship with your 10th house lord will determine whether "
                f"this period brings promotions, new ventures, or consolidation. "
                f"Jupiter's transit through key houses also opens opportunities.\n\n"
                f"Remedy: Light a sesame oil lamp on Saturdays and recite the Navagraha mantra "
                f"to strengthen Saturn's supportive influence on your professional path. ✨"
            )

        elif any(w in msg for w in ["health", "illness", "sick", "disease", "arogya", "body"]):
            reply = (
                f"Health in your chart, {name}, is primarily seen through the 1st and 6th houses "
                f"and their lords. For a {lagna} Lagna, specific body parts and health tendencies "
                f"are connected to your rising sign.\n\n"
                f"Your current {maha_str} ({antar_str}) influences your vitality. Malefic dashas "
                f"can lower resistance, while benefic ones generally support good health. "
                f"Your {rasi} Moon sign also indicates emotional health — stress patterns that "
                f"can manifest physically.\n\n"
                f"Remedy: Practice Surya Namaskar at sunrise daily and follow a routine aligned "
                f"with your constitution. Offer water to the Sun each morning to strengthen "
                f"the Sun's vitality in your chart. 🌿"
            )

        elif any(w in msg for w in ["gemstone", "gem", "stone", "wear", "ratna", "crystal"]):
            reply = (
                f"Gemstones for your {lagna} Lagna, {name}: the primary gem strengthens your "
                f"Lagna lord. As a {lagna} native, wearing the gem of your Lagna lord "
                f"on the correct day and finger enhances overall vitality and life force.\n\n"
                f"For your current {maha_str}, wearing the gemstone of the Mahadasha lord "
                f"can amplify its positive qualities. However, this must be prescribed only after "
                f"verifying that planet is favourably placed in your specific chart — a malefic "
                f"Mahadasha lord's gem can intensify challenges rather than relieve them.\n\n"
                f"Always have gems energised with the appropriate mantra by a knowledgeable "
                f"pandit before wearing. 💎"
            )

        elif any(w in msg for w in ["remedy", "remedies", "mantra", "puja", "pariharam", "solution"]):
            reply = (
                f"For your current {maha_str} ({antar_str}), {name}, these remedies are indicated:\n"
                f"• Chant the Beeja Mantra of the Mahadasha planet 108× on its day\n"
                f"• Light a lamp with the oil associated with the Mahadasha planet on its day\n"
                f"• Donate items ruled by the Mahadasha planet to the underprivileged\n"
                f"• Visit the temple of the presiding deity of your {nakshatra} Nakshatra\n\n"
                f"For your {lagna} Lagna specifically, strengthening the Lagna lord through its "
                f"mantra and gem (after proper prescription) brings overall wellbeing and clarity "
                f"of purpose. 🙏"
            )

        elif any(w in msg for w in ["muhurtham", "muhurta", "auspicious", "neram", "timing", "when"]):
            today = datetime.date.today()
            reply = (
                f"For auspicious timing, {name}, today's key windows are:\n"
                f"• Brahma Muhurta: 4:30 AM – 6:00 AM (ideal for spiritual practices and new intentions)\n"
                f"• Abhijit Muhurta: 11:48 AM – 12:36 PM (excellent for important tasks and decisions)\n"
                f"• Pradosh Kaal: 6:00 PM – 7:30 PM (for worship and family matters)\n\n"
                f"For your {lagna} Lagna, the hora (planetary hour) of your Lagna lord is always "
                f"auspicious for new beginnings. Your current {maha_str} also indicates which "
                f"days of the week are most powerful for you. "
                f"Avoid Rahu Kaal for new ventures as it is inauspicious across all charts. 📅"
            )

        elif any(w in msg for w in ["today", "daily", "forecast", "prediction", "indru"]):
            reply = (
                f"For today's forecast, {name}, as a {lagna} Lagna with {rasi} Moon — "
                f"the planetary transits activate different areas of your chart each day. "
                f"Your current {maha_str} ({antar_str}) sets the backdrop for daily experiences.\n\n"
                f"Today, focus on activities aligned with your Lagna lord's significations. "
                f"Your {nakshatra} Nakshatra makes you particularly receptive to intuitive guidance — "
                f"trust your instincts for important decisions today. "
                f"Avoid starting new projects during inauspicious horas for best outcomes. ✦"
            )

        else:
            if birth:
                reply = (
                    f"Namaskaram, {name}! 🙏 I have your complete birth chart:\n"
                    f"Lagna: {lagna} | Rasi: {rasi} | Nakshatra: {nakshatra}\n"
                    f"Current Period: {maha_str} ({antar_str})\n\n"
                    f"I can give you personalised Vedic guidance based on your chart on any topic — "
                    f"career, relationships, health, gemstones, remedies, muhurtham, or your dasha analysis. "
                    f"What would you like to explore in your chart today? ✦"
                )
            else:
                reply = (
                    "Namaskaram! The cosmos holds unique wisdom for each soul on their journey. 🙏\n\n"
                    "To give you truly personalised Vedic readings, I need your birth chart — "
                    "please complete your profile with your date, time, and place of birth. "
                    "Once I have your chart, I can answer questions about your Lagna, Nakshatra, "
                    "Dasha periods, and give guidance specific to your planetary positions.\n\n"
                    "Without a birth chart, I can only offer general Vedic knowledge. "
                    "Would you like to complete your profile now? ✦"
                )

        suggestions = _SUGGESTIONS[_sug_idx % len(_SUGGESTIONS)]
        _sug_idx += 1
        return AIChatResponse(reply=reply, suggested_questions=suggestions)
