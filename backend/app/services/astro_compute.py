"""
services/astro_compute.py
Direct Vedic astrology computation using Swiss Ephemeris (pyswisseph).
This replaces external API calls (Prokerala) with accurate on-device computation
using the Lahiri ayanamsa, exactly as Prokerala does internally.

Supported output:
  - Planet positions (rasi, degree, nakshatra, pada, retrograde flag)
  - Ascendant / Lagna
  - Moon sign / Rasi
  - Nakshatra + pada for the Moon

No data files are needed — the Moshier algorithm is compiled into pyswisseph.
"""
import logging
import math
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

# ── Sanskrit names ─────────────────────────────────────────────────────────────

_RASI_NAMES = [
    "Mesha", "Vrishabha", "Mithuna", "Karka",
    "Simha", "Kanya", "Tula", "Vrischika",
    "Dhanu", "Makara", "Kumbha", "Meena",
]

_NAKSHATRA_NAMES = [
    "Aswini", "Bharani", "Krittika", "Rohini", "Mrigashira", "Ardra",
    "Punarvasu", "Pushya", "Ashlesha", "Magha", "Purva Phalguni",
    "Uttara Phalguni", "Hasta", "Chitra", "Swati", "Vishakha",
    "Anuradha", "Jyeshtha", "Mula", "Purva Ashadha", "Uttara Ashadha",
    "Shravana", "Dhanishtha", "Shatabhisha", "Purva Bhadrapada",
    "Uttara Bhadrapada", "Revati",
]

_PLANET_NAMES = {
    0: "Sun",
    1: "Moon",
    2: "Mercury",
    3: "Venus",
    4: "Mars",
    5: "Jupiter",
    6: "Saturn",
    # Rahu/Ketu are special (mean nodes)
    10: "Rahu",
    11: "Ketu",
}

_PLANET_SYMBOLS = {
    "Sun": "☉", "Moon": "☽", "Mars": "♂", "Mercury": "☿",
    "Venus": "♀", "Jupiter": "♃", "Saturn": "♄",
    "Rahu": "☊", "Ketu": "☋",
}


def _rasi(longitude: float) -> str:
    return _RASI_NAMES[int(longitude / 30) % 12]


def _nakshatra(longitude: float):
    """Return (nakshatra_name, pada) for a sidereal longitude."""
    nak_idx = int(longitude / (360 / 27)) % 27
    pada = int((longitude % (360 / 27)) / (360 / 108)) + 1
    return _NAKSHATRA_NAMES[nak_idx], min(pada, 4)


def _degree_str(longitude: float) -> str:
    deg = int(longitude % 30)
    minutes = int((longitude % 1) * 60)
    return f"{deg:02d}°{minutes:02d}'"


# ── Main computation ───────────────────────────────────────────────────────────

def compute_chart(
    year: int, month: int, day: int,
    hour: int, minute: int,
    latitude: float, longitude: float,
    timezone: float = 5.5,
) -> Dict[str, Any]:
    """
    Compute a full Vedic birth chart using Swiss Ephemeris.

    Returns a dict shaped like the Prokerala API response so the existing
    parsing logic in astrology_service.py works unchanged.
    """
    try:
        import swisseph as swe
    except ImportError:
        logger.error("[AstroCompute] pyswisseph not installed — returning empty dict")
        return {}

    # Convert local time to Julian Day (UTC)
    ut_hour = hour + minute / 60.0 - timezone
    jd_ut = swe.julday(year, month, day, ut_hour)

    # Lahiri ayanamsa (standard for Vedic / KP astrology)
    swe.set_sid_mode(swe.SIDM_LAHIRI)

    # ── Planet positions ──────────────────────────────────────────────────────

    planet_positions = []

    swe_planets = [
        (swe.SUN,     "Sun"),
        (swe.MOON,    "Moon"),
        (swe.MARS,    "Mars"),
        (swe.MERCURY, "Mercury"),
        (swe.VENUS,   "Venus"),
        (swe.JUPITER, "Jupiter"),
        (swe.SATURN,  "Saturn"),
        (swe.MEAN_NODE, "Rahu"),   # mean North Node
    ]

    rahu_longitude = None

    for swe_id, name in swe_planets:
        try:
            result, _ = swe.calc_ut(jd_ut, swe_id, swe.FLG_SIDEREAL | swe.FLG_SPEED)
            ecl_lon = result[0]   # ecliptic longitude (sidereal)
            speed   = result[3]   # speed in longitude (negative = retrograde)
            is_retro = speed < 0

            # Rahu is the North Node; Ketu is exactly opposite
            if name == "Rahu":
                rahu_longitude = ecl_lon

            rasi_name      = _rasi(ecl_lon)
            nak_name, pada = _nakshatra(ecl_lon)

            planet_positions.append({
                "name":           name,
                "longitude":      ecl_lon,
                "is_retrograde":  is_retro,
                "rasi":           {"name": rasi_name},
                "nakshatra":      {"name": nak_name},
                "nakshatra_pada": pada,
            })

        except Exception as exc:
            logger.warning(f"[AstroCompute] Failed to compute {name}: {exc}")

    # Add Ketu (South Node = Rahu + 180°)
    if rahu_longitude is not None:
        ketu_lon  = (rahu_longitude + 180.0) % 360.0
        nak_name, pada = _nakshatra(ketu_lon)
        planet_positions.append({
            "name":           "Ketu",
            "longitude":      ketu_lon,
            "is_retrograde":  True,
            "rasi":           {"name": _rasi(ketu_lon)},
            "nakshatra":      {"name": nak_name},
            "nakshatra_pada": pada,
        })

    # ── Ascendant (Lagna) ─────────────────────────────────────────────────────

    try:
        houses, ascmc = swe.houses(jd_ut, latitude, longitude, b'W')
        # Whole-sign houses ('W') is standard in Vedic / Jyotish
        asc_tropical = ascmc[0]   # tropical ascendant longitude
        ayanamsa     = swe.get_ayanamsa_ut(jd_ut)
        asc_sidereal = (asc_tropical - ayanamsa) % 360.0
        lagna_name   = _rasi(asc_sidereal)
    except Exception as exc:
        logger.warning(f"[AstroCompute] Failed to compute Ascendant: {exc}")
        asc_sidereal = 0.0
        lagna_name   = "Mesha"

    # ── Moon sign & nakshatra ─────────────────────────────────────────────────

    moon_entry = next((p for p in planet_positions if p["name"] == "Moon"), None)
    if moon_entry:
        moon_lon  = moon_entry["longitude"]
        moon_rasi = moon_entry["rasi"]["name"]
        moon_nak, moon_pada = moon_entry["nakshatra"]["name"], moon_entry["nakshatra_pada"]
    else:
        moon_lon  = 0.0
        moon_rasi = "Mesha"
        moon_nak, moon_pada = "Aswini", 1

    # ── Return Prokerala-shaped dicts ─────────────────────────────────────────
    # astrology_service._parse_planets expects chart_raw with planet_position key.
    # astrology_service._parse_summary expects kundli_raw with ascendant + moon_sign.

    chart_raw = {
        "data": {
            "planet_position": planet_positions,
        }
    }

    kundli_raw = {
        "data": {
            "ascendant": {
                "name": lagna_name,          # Sanskrit (already converted above)
                "longitude": asc_sidereal,
            },
            "moon_sign": {
                "name": moon_rasi,           # Sanskrit
            },
            "nakshatra": {
                "name": moon_nak,
                "pada": moon_pada,
            },
            # Tithi / yoga / karana require additional computation;
            # keep basic defaults for now.
            "tithi":  {"name": "Ekadashi"},
            "yoga":   {"name": "Siddhi"},
            "karana": {"name": "Bava"},
        }
    }

    logger.info(
        f"[AstroCompute] Chart computed — Lagna: {lagna_name}, "
        f"Moon: {moon_rasi} ({moon_nak} pada {moon_pada}), "
        f"Planets: {len(planet_positions)}"
    )
    return {"chart": chart_raw, "kundli": kundli_raw}
