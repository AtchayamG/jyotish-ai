"""
services/ai_chat_service.py
Jyotish AI chatbot powered by OpenAI GPT-4o-mini.
Falls back to rule-based responses when OPENAI_API_KEY is not set.

Set in Render env vars:
  OPENAI_API_KEY = your_openai_key
  OPENAI_MODEL   = gpt-4o-mini  (default — cost efficient)
"""
import logging
from typing import List

from app.core.config import settings
from app.core.http_client import http_client
from app.schemas.astrology_schema import AIChatRequest, AIChatResponse, ChatMessage

logger = logging.getLogger(__name__)

# ── System prompt ─────────────────────────────────────────────────────────────
_SYSTEM_PROMPT = """You are Jyotish AI, an expert Vedic and Tamil astrologer. You have deep knowledge of:
- Parasara, KP, and Nadi Jyotish systems
- Brihat Parashara Hora Shastra and classical texts
- Tamil Jyotish (Tamizh Jothidam) and Nadi leaf reading
- Muhurtham (auspicious timing) calculations
- Gemstone remedies, mantras, rituals, Vastu Shastra
- Nakshatra characteristics, Dasha periods, transits

Response rules:
1. Give compassionate, insightful guidance rooted in Vedic wisdom
2. Mention specific planets, houses, and dasha periods where relevant
3. Suggest practical remedies when discussing challenges
4. Frame predictions as "indications" and "planetary influences" — never absolute
5. If user writes in Tamil, respond fully in Tamil script
6. Keep responses concise (2–3 paragraphs) unless deep analysis is requested
7. End with 1–2 follow-up question suggestions on a new line starting with "Suggestions:"
8. Be respectful of all spiritual traditions

When birth details are provided, personalise your answers to that chart."""

_SUGGESTIONS = [
    ["What does my current dasha indicate?", "Which gemstone should I wear?"],
    ["When will my career improve?", "What remedies help my situation?"],
    ["Tell me about my marriage prospects", "What are today's auspicious times?"],
    ["Explain my rising sign", "How can I strengthen Jupiter in my chart?"],
]
_sug_idx = 0


class AIChatService:

    async def chat(self, req: AIChatRequest) -> AIChatResponse:
        if not settings.OPENAI_API_KEY:
            logger.info("[ChatSvc] No OpenAI key — using rule-based fallback")
            return self._rule_based(req.message)

        try:
            return await self._openai(req)
        except Exception as e:
            logger.error(f"[ChatSvc] OpenAI error: {e} — falling back to rules")
            return self._rule_based(req.message)

    async def _openai(self, req: AIChatRequest) -> AIChatResponse:
        # Build system message
        system = _SYSTEM_PROMPT
        if req.user_birth_details:
            b = req.user_birth_details
            system += (
                f"\n\nUser birth details: {b.name}, born "
                f"{b.day:02d}/{b.month:02d}/{b.year} at {b.hour:02d}:{b.minute:02d}, "
                f"coordinates {b.latitude},{b.longitude}, timezone UTC{b.timezone:+.1f}."
            )

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
                "max_tokens":  600,
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
            suggestions = _SUGGESTIONS[_sug_idx % len(_SUGGESTIONS)]

        return AIChatResponse(reply=full_reply, suggested_questions=suggestions)

    def _rule_based(self, message: str) -> AIChatResponse:
        global _sug_idx
        msg = message.lower()

        if any(w in msg for w in ["marry", "marriage", "wedding", "vivah", "kalyanam"]):
            reply = (
                "Based on Vedic astrology principles, marriage timing is primarily determined "
                "by the 7th house lord's Mahadasha and Venus's transit over key natal positions. "
                "Your Venus Mahadasha period indicates a strong window for significant relationships "
                "during 2025–2027. A detailed Navamsa (D9) chart analysis will give more precise timing.\n\n"
                "Remedy: Chant 'Om Shukraya Namah' 108 times on Fridays and offer white flowers "
                "to the Goddess. Wearing a Diamond or White Sapphire on the right ring finger "
                "on a Friday morning also strengthens Venus. 🙏"
            )
        elif any(w in msg for w in ["career", "job", "work", "profession", "business", "thozhil"]):
            reply = (
                "Jupiter's aspect on your 10th house is very favourable for career advancement. "
                "The current Rahu Mahadasha tends to bring unconventional but highly rewarding "
                "opportunities, especially in technology, finance, and international fields. "
                "This is an excellent period to take calculated professional risks.\n\n"
                "Remedy: Light a sesame oil lamp on Saturdays and donate black sesame to the needy "
                "to pacify Rahu's restlessness. Wearing a Hessonite (Gomed) after proper energisation "
                "can amplify Rahu's positive career effects. ✨"
            )
        elif any(w in msg for w in ["health", "illness", "sick", "disease", "arogya"]):
            reply = (
                "Your 6th house lord's placement suggests paying particular attention to digestive "
                "health and stress management. Saturn's influence in your chart calls for regular, "
                "disciplined health routines — irregular habits tend to create chronic issues.\n\n"
                "Remedy: Practice Surya Namaskar at sunrise daily. Follow a Sattvic diet and avoid "
                "processed foods on Saturdays. Drinking water from a copper vessel each morning "
                "strengthens the Sun's vitality in your chart. 🌿"
            )
        elif any(w in msg for w in ["gemstone", "gem", "stone", "wear", "ratna"]):
            reply = (
                "For your Mesha Lagna, the primary gemstone is Red Coral (Moonga) worn in a copper "
                "ring on the ring finger of the right hand, ideally on a Tuesday during Mars hora. "
                "This strengthens Mars, your lagna lord.\n\n"
                "Additionally: Yellow Sapphire (Pukhraj) for Jupiter's blessings in the 4th house, "
                "and Blue Sapphire (Neelam) for Saturn if it is well-placed. Always get gemstones "
                "energised with the appropriate mantra by a knowledgeable pandit before wearing. 💎"
            )
        elif any(w in msg for w in ["remedy", "remedies", "mantra", "puja", "pariharam"]):
            reply = (
                "For your current Rahu–Venus Dasha period:\n"
                "• Chant Rahu Beeja Mantra 'Om Raam Rahave Namah' 108× on Saturdays at dusk\n"
                "• Visit a Durga or Kali temple on Fridays for Venus strengthening\n"
                "• Offer blue flowers and coconut to Lord Shiva on Saturdays\n"
                "• Donate blue/black items to the underprivileged on Saturdays\n\n"
                "These remedies balance Rahu's disruptive energy while channelling Venus's grace "
                "for harmony in relationships and creative pursuits. 🙏"
            )
        elif any(w in msg for w in ["today", "daily", "forecast", "prediction", "indru"]):
            reply = (
                "Today's planetary alignment is favourable for new beginnings and communications. "
                "Mercury's strong position enhances intellectual clarity — ideal for important "
                "conversations, signing agreements, or starting new projects.\n\n"
                "Avoid major financial decisions after 4 PM IST as the muhurta becomes less "
                "auspicious. Lucky number: 7. Lucky colour: Royal Blue. Overall score: 8/10 ✦"
            )
        elif any(w in msg for w in ["dasha", "mahadasha", "antardasha", "period"]):
            reply = (
                "Your current Rahu Mahadasha (2018–2036) with Venus Antardasha (until Sep 2026) "
                "is a period of transformation and material accumulation. Rahu amplifies "
                "Venus's qualities — heightened desires, artistic sensibilities, and relationship "
                "focus are prominent themes.\n\n"
                "This period favours careers in technology, media, entertainment, and finance. "
                "Relationships formed during this period tend to be intense and karmic. "
                "The Sun Antardasha following (Sep 2026) will bring clarity and leadership opportunities. ✨"
            )
        elif any(w in msg for w in ["muhurtham", "muhurta", "auspicious", "time", "neram"]):
            reply = (
                "For today, the most auspicious time windows are:\n"
                "• Brahma Muhurta: 4:30 AM – 6:00 AM (ideal for spiritual practices)\n"
                "• Abhijit Muhurta: 11:48 AM – 12:36 PM (excellent for important tasks)\n"
                "• Pradosh Kaal: 6:00 PM – 7:30 PM (for worship and family matters)\n\n"
                "Avoid Rahu Kaal (7:30 AM – 9:00 AM on Thursday) for new ventures. "
                "Rohini Nakshatra is currently active — highly favourable for agriculture, "
                "buying property, and starting businesses. 📅"
            )
        else:
            reply = (
                "Namaskaram! The cosmos holds unique wisdom for each soul on their journey. 🙏\n\n"
                "Your planetary positions suggest a dynamic and spiritually evolving path. "
                "I can provide detailed Vedic guidance on career, relationships, health, "
                "gemstone remedies, auspicious timing (muhurtham), or your current dasha period.\n\n"
                "Please share what area of life you would like guidance on, and if you have "
                "your birth details handy, the predictions will be much more personalised. ✦"
            )

        suggestions = _SUGGESTIONS[_sug_idx % len(_SUGGESTIONS)]
        _sug_idx += 1
        return AIChatResponse(reply=reply, suggested_questions=suggestions)
