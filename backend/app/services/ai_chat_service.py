"""
services/ai_chat_service.py
Jyotish AI chatbot — context-aware, intent-driven, with Firestore chat history.

Architecture:
  1. Fetch user birth chart from their stored profile (no per-request upload)
  2. Detect user intent (career / marriage / dasha / lagna / etc.)
  3. Build a FOCUSED prompt — inject only chart data relevant to the intent
  4. Include last 10 messages from Firestore for true conversation memory
  5. Customize response length based on intent complexity
  6. Save every exchange to Firestore (per-user chat history)

Env vars required:
  OPENAI_API_KEY  — your OpenAI key
  OPENAI_MODEL    — default: gpt-4o-mini
"""
import logging
import math
import datetime
import time as time_mod
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
    nak_span = 360.0 / 27.0
    nak_idx  = int(moon_longitude / nak_span) % 27
    frac_in_nak = (moon_longitude % nak_span) / nak_span

    start_planet = _NAK_TO_DASHA[nak_idx]
    start_years  = _DASHA_YEARS[start_planet]
    elapsed_years = frac_in_nak * start_years
    balance_years = start_years - elapsed_years

    seq_planets = [p for p, _ in _DASHA_SEQUENCE]
    start_idx = seq_planets.index(start_planet)

    birth_dt = datetime.date(birth_year, birth_month, birth_day)

    def add_years(d: datetime.date, y: float) -> datetime.date:
        return d + datetime.timedelta(days=int(y * 365.25))

    today = datetime.date.today()
    cursor = birth_dt

    for i in range(9):
        idx = (start_idx + i) % 9
        planet, years = _DASHA_SEQUENCE[idx]
        period_years = balance_years if i == 0 else years
        end = add_years(cursor, period_years)

        if cursor <= today < end or (i == 8 and today >= cursor):
            maha_start = cursor
            maha_end   = end
            total_maha_days = (maha_end - maha_start).days or 1
            antar_cursor = maha_start
            current_antar = None
            antar_end = None

            for j in range(9):
                antar_idx = (seq_planets.index(planet) + j) % 9
                antar_planet, antar_years = _DASHA_SEQUENCE[antar_idx]
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
    planets   = chart_data.get("planet_position", [])

    planet_lines = []
    moon_lon = 0.0
    for p in planets:
        name  = p.get("name", "")
        rasi  = p.get("rasi", {}).get("name", "")
        nak   = p.get("nakshatra", {}).get("name", "")
        retro = " (R)" if p.get("is_retrograde") else ""
        house = p.get("house", "")
        planet_lines.append(f"  {name}: {rasi}, House {house}, {nak}{retro}")
        if name == "Moon":
            moon_lon = p.get("longitude", 0.0)

    try:
        maha_str, antar_str = _compute_current_dasha(
            moon_lon, birth.year, birth.month, birth.day)
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
        "CRITICAL: ALL answers MUST reference the above chart data.",
        "Never say you don't know the user's chart — the complete chart is above.",
    ]
    return "\n".join(lines)


# ── Intent detection ──────────────────────────────────────────────────────────

_INTENT_MAP = {
    "lagna":    ["lagna", "ascendant", "rising sign", "lagnam"],
    "rasi":     ["rasi", "moon sign", "rashi", "moon rasi"],
    "nakshatra":["nakshatra", "birth star", "janma nakshatra", "star"],
    "dasha":    ["dasha", "mahadasha", "antardasha", "period", "vimshottari", "vimsottari", "dasa"],
    "career":   ["career", "job", "work", "profession", "business", "promotion", "thozhil", "office"],
    "marriage": ["marry", "marriage", "wedding", "vivah", "kalyanam", "partner", "spouse", "relationship", "love"],
    "health":   ["health", "illness", "sick", "disease", "arogya", "body", "pain", "medical"],
    "finance":  ["money", "finance", "wealth", "salary", "income", "investment", "loss", "profit", "dhana"],
    "gemstone": ["gemstone", "gem", "stone", "ratna", "crystal", "wear", "ring"],
    "remedy":   ["remedy", "remedies", "mantra", "puja", "pariharam", "solution", "prayer", "japa"],
    "timing":   ["muhurtham", "muhurta", "auspicious", "neram", "rahu kaal", "rahu kal", "auspicious time"],
    "forecast": ["today", "daily", "this week", "this month", "forecast", "prediction", "indru"],
    "planets":  ["saturn", "jupiter", "mars", "venus", "mercury", "sun", "moon", "rahu", "ketu", "planet", "graha"],
    "transit":  ["transit", "gochara", "current position", "moving through"],
    "child":    ["child", "children", "baby", "pregnancy", "puthra", "kuzhanthai"],
    "education":["education", "study", "exam", "college", "university", "degree", "padippu"],
    "travel":   ["travel", "abroad", "foreign", "visa", "migration", "prabas"],
}


def _detect_intent(message: str) -> str:
    """Detect the primary intent of the user message. Returns an intent key."""
    msg = message.lower()
    for intent, keywords in _INTENT_MAP.items():
        if any(kw in msg for kw in keywords):
            return intent
    return "general"


# ── Intent-aware prompt builder ───────────────────────────────────────────────

_INTENT_INSTRUCTIONS = {
    "lagna":    "User is asking about their Ascendant. Answer directly using the Lagna from the chart. Explain its characteristics concisely (2 short paragraphs).",
    "rasi":     "User is asking about their Moon sign. Answer directly using Rasi from the chart. Explain emotional nature and how current dasha affects it.",
    "nakshatra":"User is asking about birth star. Answer directly using Janma Nakshatra from the chart. Include deity, ruling planet, and karmic qualities.",
    "dasha":    "User is asking about their Dasha period. Explain the current Mahadasha AND Antardasha clearly. Give realistic expectations for this period (1–2 paragraphs). Avoid long generic explanations.",
    "career":   "User is asking about career. Focus ONLY on 10th house, Saturn, and current Dasha implications for work. Give a 1–2 month short-term prediction. End with ONE specific remedy.",
    "marriage": "User is asking about marriage/relationships. Focus on 7th house, Venus, and Dasha timing. Give concrete indications. ONE remedy at the end.",
    "health":   "User is asking about health. Focus on 1st/6th houses, Sun vitality, and current dasha effects on health. Give practical advice. ONE remedy.",
    "finance":  "User is asking about finances. Focus on 2nd/11th houses, Jupiter, and current dasha effects on wealth. Short-term outlook. ONE remedy.",
    "gemstone": "User is asking about gemstones. Give ONE primary gemstone recommendation for their Lagna lord with rationale. Mention metal, finger, day to wear. Keep it brief.",
    "remedy":   "User is asking for remedies. Give 3 specific, actionable remedies for their current Mahadasha. Include mantra, day, and what to donate. Keep it practical.",
    "timing":   "User is asking about auspicious timing. Give today's Brahma Muhurta, Abhijit Muhurta, and Rahu Kaal timings. Brief and specific.",
    "forecast": "User wants today's prediction. Based on Moon's current transit and their Rasi, give a short personal prediction for today (3–4 sentences max).",
    "planets":  "User is asking about a specific planet. Analyse that planet's placement in their chart specifically — sign, house, nakshatra. 2 paragraphs.",
    "transit":  "User is asking about planetary transits. Explain how current major transits (Jupiter/Saturn/Rahu) affect their specific chart positions.",
    "child":    "User is asking about children/pregnancy. Focus on 5th house and its lord in their chart. Current dasha implications.",
    "education":"User is asking about education. Focus on 4th/5th houses, Mercury, and Jupiter in their chart.",
    "travel":   "User is asking about travel/foreign. Focus on 9th/12th houses and current dasha for travel opportunities.",
    "general":  "Give a brief friendly overview of their chart highlights and invite them to ask about a specific area.",
}

_RESPONSE_TOKENS = {
    "lagna": 350, "rasi": 350, "nakshatra": 400,
    "dasha": 500, "career": 500, "marriage": 500, "health": 450,
    "finance": 450, "gemstone": 300, "remedy": 400, "timing": 300,
    "forecast": 300, "planets": 500, "transit": 500,
    "child": 400, "education": 400, "travel": 400, "general": 400,
}


def _build_focused_context(chart_context: str, intent: str) -> str:
    """
    For simple intents (lagna/rasi/nakshatra/timing/gemstone),
    strip the full planet list and include only the key header lines.
    This reduces token count and prevents the model from over-explaining.
    """
    if not chart_context:
        return ""

    simple_intents = {"lagna", "rasi", "nakshatra", "gemstone", "timing", "forecast", "remedy"}
    if intent not in simple_intents:
        return chart_context  # Full context for analysis-heavy intents

    # Include only header through antardasha line; skip planet list
    lines = chart_context.splitlines()
    keep = []
    skip = False
    for line in lines:
        if "Planetary Positions:" in line:
            skip = True
        if "=== END OF BIRTH CHART ===" in line:
            skip = False
            keep.append(line)
            continue
        if not skip:
            keep.append(line)
    return "\n".join(keep)


# ── Base system prompt ────────────────────────────────────────────────────────

_BASE_SYSTEM = """You are Jyotish AI, a deeply knowledgeable personal Vedic and Tamil astrologer. You have mastery of:
- Parasara, KP, and Nadi Jyotish systems
- Brihat Parashara Hora Shastra and classical texts
- Tamil Jyotish (Tamizh Jothidam) and Nadi leaf reading
- Muhurtham (auspicious timing), Gemstone remedies, Mantras, Vastu Shastra
- Nakshatra characteristics, Dasha periods, and planetary transits

STRICT RULES:
1. You are a PERSONAL astrologer. ALL answers MUST be based ONLY on the birth chart provided below.
2. NEVER give generic predictions. Reference the user's specific Lagna, Rasi, Nakshatra, or Dasha every time.
3. If asked "what is my lagna / rasi / nakshatra / dasha" — answer DIRECTLY from the chart. Never say you don't know.
4. If NO chart is attached — ask the user to complete their profile.
5. Frame as "indications" and "planetary influences" — never absolute certainties.
6. If user writes in Tamil, respond FULLY in Tamil script.
7. Keep responses CONCISE and DIRECT — no long preambles, no repeating the full chart.
8. End with 1–2 follow-up suggestions on a new line: "Suggestions: ..."
9. NEVER repeat the same response to similar questions — vary based on context.
10. Match response length to question complexity — simple questions deserve short answers."""


def _build_system_prompt(chart_context: str, intent: str) -> str:
    """Combine base prompt + intent instruction + focused chart context."""
    instruction = _INTENT_INSTRUCTIONS.get(intent, _INTENT_INSTRUCTIONS["general"])
    return (
        _BASE_SYSTEM
        + f"\n\nFOCUS FOR THIS RESPONSE: {instruction}"
        + _build_focused_context(chart_context, intent)
    )


# ── Fallback suggestions ──────────────────────────────────────────────────────

_SUGGESTIONS = [
    ["What does my current dasha indicate?", "Which gemstone should I wear?"],
    ["When will my career improve?", "What remedies help my situation?"],
    ["Tell me about my marriage prospects", "What are today's auspicious times?"],
    ["Explain my lagna's characteristics", "How can I strengthen Jupiter in my chart?"],
    ["What does my nakshatra reveal?", "Which houses are strongest in my chart?"],
]
_sug_idx = 0


# ── Firestore chat history ────────────────────────────────────────────────────

async def _load_history(user_id: str) -> List[ChatMessage]:
    """Load last 10 messages from Firestore chats/{user_id}/messages."""
    try:
        from app.core.firebase import get_db
        import asyncio
        loop = asyncio.get_running_loop()

        def _fetch():
            db = get_db()
            docs = list(
                db.collection("chats").document(user_id)
                  .collection("messages")
                  .order_by("ts")
                  .limit_to_last(10)
                  .stream()
            )
            return [{"role": d.to_dict()["role"], "content": d.to_dict()["content"]} for d in docs]

        raw = await loop.run_in_executor(None, _fetch)
        return [ChatMessage(role=r["role"], content=r["content"]) for r in raw]
    except Exception as e:
        logger.warning(f"[ChatSvc] load_history failed: {e}")
        return []


async def _save_messages(user_id: str, user_msg: str, ai_reply: str) -> None:
    """Save user + AI messages to Firestore chats/{user_id}/messages."""
    try:
        from app.core.firebase import get_db
        import asyncio
        loop = asyncio.get_running_loop()
        ts = int(time_mod.time() * 1000)

        def _write():
            db = get_db()
            col = db.collection("chats").document(user_id).collection("messages")
            col.add({"role": "user",      "content": user_msg, "ts": ts})
            col.add({"role": "assistant", "content": ai_reply, "ts": ts + 1})

        await loop.run_in_executor(None, _write)
    except Exception as e:
        logger.warning(f"[ChatSvc] save_messages failed: {e}")


# ── Main service ──────────────────────────────────────────────────────────────

class AIChatService:

    async def chat(
        self,
        req: AIChatRequest,
        user_id: Optional[str] = None,
        birth: Optional[BirthDetails] = None,
    ) -> AIChatResponse:
        # Birth details: prefer server-fetched profile, fall back to client-sent
        birth_details = birth or req.user_birth_details

        # Detect intent FIRST — shapes everything downstream
        intent = _detect_intent(req.message)
        logger.info(f"[ChatSvc] intent={intent}, user={user_id}")

        # Compute chart context (cached per user ideally; here computed fresh)
        chart_context = ""
        if birth_details:
            chart_context = _compute_kundli_context(birth_details)

        # Load conversation history from Firestore (beats client-sent history
        # because Firestore persists across sessions)
        if user_id:
            history = await _load_history(user_id)
            if not history:
                history = req.history[-10:]  # fallback to client history
        else:
            history = req.history[-10:]

        # Generate reply
        result: AIChatResponse
        if not settings.OPENAI_API_KEY:
            result = self._rule_based(req.message, birth_details, chart_context, intent)
        else:
            try:
                result = await self._openai(req, chart_context, history, intent)
            except Exception as e:
                logger.error(f"[ChatSvc] OpenAI error: {e} — falling back to rules")
                result = self._rule_based(req.message, birth_details, chart_context, intent)

        # Persist exchange to Firestore (fire-and-forget, errors are logged not raised)
        if user_id:
            await _save_messages(user_id, req.message, result.reply)

        return result

    # ── OpenAI path ───────────────────────────────────────────────────────────

    async def _openai(
        self,
        req: AIChatRequest,
        chart_context: str,
        history: List[ChatMessage],
        intent: str,
    ) -> AIChatResponse:
        system = _build_system_prompt(chart_context, intent)
        max_tokens = _RESPONSE_TOKENS.get(intent, 600)

        messages = [{"role": "system", "content": system}]
        for h in history:
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
                "max_tokens":  max_tokens,
                "temperature": 0.75,
            },
        )

        full_reply = resp["choices"][0]["message"]["content"].strip()

        # Parse "Suggestions:" suffix
        suggestions: List[str] = []
        if "Suggestions:" in full_reply:
            parts = full_reply.split("Suggestions:", 1)
            full_reply = parts[0].strip()
            raw = parts[1].strip().split("\n")
            suggestions = [s.strip().lstrip("•-1234567890. ") for s in raw if s.strip()][:3]

        if not suggestions:
            global _sug_idx
            suggestions = _SUGGESTIONS[_sug_idx % len(_SUGGESTIONS)]
            _sug_idx += 1

        return AIChatResponse(reply=full_reply, suggested_questions=suggestions)

    # ── Rule-based fallback ────────────────────────────────────────────────────

    def _rule_based(
        self,
        message: str,
        birth: Optional[BirthDetails],
        chart_context: str,
        intent: str = "general",
    ) -> AIChatResponse:
        global _sug_idx
        msg = message.lower()

        # Extract chart facts
        lagna = "your Lagna"
        rasi = "your Moon sign"
        nakshatra = "your Nakshatra"
        name = "Seeker"
        maha_str = "your current Mahadasha"
        antar_str = "your current Antardasha"

        if birth:
            name = birth.name.split()[0] if birth.name else "Seeker"
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

        if intent == "lagna":
            reply = (
                f"Namaskaram, {name}! Your Lagna (Ascendant) is **{lagna}**.\n\n"
                f"This sign was rising on the eastern horizon at the moment of your birth. "
                f"It shapes your personality, physical appearance, and overall life direction. "
                f"The lord of {lagna} is especially significant — its placement determines how "
                f"your Lagna traits manifest. Your current {maha_str} further colours these qualities."
            )
        elif intent == "rasi":
            reply = (
                f"Your Rasi (Moon Sign) is **{rasi}**, {name}.\n\n"
                f"In Vedic astrology, the Moon sign reveals your emotional nature and inner world — "
                f"it's equally important as the Lagna. Your {nakshatra} Nakshatra adds nuance to "
                f"how you process emotions. During {maha_str}, your Moon sign's qualities are "
                f"particularly active."
            )
        elif intent == "nakshatra":
            reply = (
                f"Your Janma Nakshatra (birth star) is **{nakshatra}**, {name}.\n\n"
                f"This lunar mansion reveals your deepest karmic patterns and innate talents. "
                f"It has a specific deity, planetary ruler, and symbol that define your path. "
                f"Your current {maha_str} interacts with your Nakshatra lord to shape present themes."
            )
        elif intent == "dasha":
            reply = (
                f"You are in the **{maha_str}** with **{antar_str}**, {name}.\n\n"
                f"The Mahadasha planet governs your life's overarching themes in this period. "
                f"The Antardasha shapes day-to-day experiences within that framework. Their "
                f"natural significations and house placements in your chart determine the quality "
                f"of results. Propitiating the Mahadasha lord can ease difficult phases."
            )
        elif intent == "career":
            reply = (
                f"Career for a {lagna} Lagna native like you, {name}, is governed by the 10th "
                f"house and its lord, alongside Saturn (karma karaka).\n\n"
                f"Your {maha_str} ({antar_str}) is the key timing factor now. This dasha planet's "
                f"relation with your 10th lord will bring promotions or new opportunities. "
                f"Focus on consistent effort during this period.\n\n"
                f"*Remedy:* Light a sesame oil lamp on Saturdays. Recite 'Om Shanaischaraya Namah' "
                f"108× for Saturn's blessings on your career. ✨"
            )
        elif intent == "marriage":
            reply = (
                f"For marriage timing, {name}, your 7th house and Venus are key. "
                f"The 7th lord's Dasha/Antardasha periods bring significant relationship events.\n\n"
                f"Your current {maha_str} ({antar_str}) provides the timing context. Jupiter "
                f"transiting over the 7th house or natal Venus also activates relationships.\n\n"
                f"*Remedy:* Chant 'Om Shukraya Namah' 108× on Fridays. Offer white flowers "
                f"to the Goddess for Venus's blessings. 🙏"
            )
        elif intent == "health":
            reply = (
                f"Health is seen through the 1st and 6th houses for a {lagna} Lagna, {name}.\n\n"
                f"Your {maha_str} ({antar_str}) directly affects your vitality. Your {rasi} Moon "
                f"also reflects stress patterns that manifest physically.\n\n"
                f"*Remedy:* Offer water to the Sun each morning. Practice Surya Namaskar at sunrise "
                f"to strengthen solar vitality in your chart. 🌿"
            )
        elif intent == "finance":
            reply = (
                f"Finances for a {lagna} Lagna native, {name}: 2nd and 11th houses govern "
                f"wealth accumulation; Jupiter is the natural karaka for prosperity.\n\n"
                f"Your {maha_str} ({antar_str}) shapes financial developments now. "
                f"If Jupiter or 2nd/11th lords are well-placed, this period can bring gains.\n\n"
                f"*Remedy:* Chant 'Om Gurave Namah' 108× on Thursdays and offer yellow flowers "
                f"to Jupiter for financial growth. 💛"
            )
        elif intent == "gemstone":
            reply = (
                f"For your {lagna} Lagna, {name}: the primary gemstone strengthens your Lagna "
                f"lord. Wear the gem of your Lagna lord on the correct day and finger "
                f"to enhance overall vitality.\n\n"
                f"For your current {maha_str}: wearing the Mahadasha lord's gemstone amplifies "
                f"its positive qualities — but ONLY after verifying it is well-placed in your chart. "
                f"A malefic Mahadasha lord's gem can worsen challenges.\n\n"
                f"Always have gems energised with the appropriate mantra before wearing. 💎"
            )
        elif intent == "remedy":
            reply = (
                f"For your {maha_str} ({antar_str}), {name}, these remedies are indicated:\n"
                f"• Chant the Beeja Mantra of the Mahadasha planet 108× on its day\n"
                f"• Light a lamp with its associated oil on its day\n"
                f"• Donate items ruled by the Mahadasha planet to the needy\n"
                f"• Visit the temple of your {nakshatra} Nakshatra's presiding deity\n\n"
                f"For {lagna} Lagna: strengthen the Lagna lord through its mantra and gem "
                f"for overall clarity and wellbeing. 🙏"
            )
        elif intent == "timing":
            reply = (
                f"Today's auspicious windows for you, {name}:\n"
                f"• **Brahma Muhurta:** 4:30 AM – 6:00 AM (spiritual practices, new intentions)\n"
                f"• **Abhijit Muhurta:** 11:48 AM – 12:36 PM (important tasks, decisions)\n"
                f"• **Pradosh Kaal:** 6:00 PM – 7:30 PM (worship, family matters)\n\n"
                f"Avoid Rahu Kaal for new ventures — it is inauspicious across all charts. "
                f"Your {lagna} Lagna lord's hora (planetary hour) is always your strongest window. 📅"
            )
        elif intent == "forecast":
            reply = (
                f"Today's forecast for you, {name} — {lagna} Lagna, {rasi} Moon:\n\n"
                f"Your {maha_str} ({antar_str}) shapes the broader backdrop. Today, focus on "
                f"activities aligned with your Lagna lord's significations. Your {nakshatra} "
                f"Nakshatra makes you receptive to intuitive guidance — trust your instincts "
                f"for important decisions. Avoid new beginnings during Rahu Kaal. ✦"
            )
        else:
            if birth:
                reply = (
                    f"Namaskaram, {name}! 🙏 Your chart at a glance:\n"
                    f"**Lagna:** {lagna} · **Rasi:** {rasi} · **Nakshatra:** {nakshatra}\n"
                    f"**Current Period:** {maha_str} ({antar_str})\n\n"
                    f"I can give you personalised guidance on career, relationships, health, "
                    f"gemstones, remedies, muhurtham, or dasha analysis. "
                    f"What would you like to explore? ✦"
                )
            else:
                reply = (
                    "Namaskaram! The cosmos holds unique wisdom for each soul. 🙏\n\n"
                    "To give you truly personalised readings, I need your birth chart. "
                    "Please complete your profile with your date, time, and place of birth. "
                    "Once I have your chart, I can give guidance specific to your planetary positions.\n\n"
                    "Would you like to complete your profile now? ✦"
                )

        suggestions = _SUGGESTIONS[_sug_idx % len(_SUGGESTIONS)]
        _sug_idx += 1
        return AIChatResponse(reply=reply, suggested_questions=suggestions)
