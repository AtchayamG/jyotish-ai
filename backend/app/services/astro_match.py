"""
services/astro_match.py
Ashtakoota Guna Milan — Vedic marriage compatibility algorithm.
Computes all 8 kutas (total 36 points) from the Moon signs and nakshatras
of both individuals. No external API required.

References: Brihat Parashara Hora Shastra, classical Ashtakoota rules.
"""
from typing import Dict, List, Tuple

# ── Nakshatra data ─────────────────────────────────────────────────────────────
# Each entry: (gana, yoni_animal, yoni_gender, varna, nadi)
#   gana:         "Deva" | "Manushya" | "Rakshasa"
#   yoni_animal:  animal symbol name
#   yoni_gender:  "M" | "F"
#   varna:        "Brahmin" | "Kshatriya" | "Vaishya" | "Shudra" | "Mixed"
#   nadi:         "Aadi" | "Madhya" | "Antya"

_NAK_DATA: List[Tuple] = [
    # idx, name,               gana,         yoni,         gen, varna,       nadi
    ( 0, "Aswini",            "Deva",       "Horse",      "M", "Vaishya",   "Aadi"),
    ( 1, "Bharani",           "Manushya",   "Elephant",   "M", "Mixed",     "Antya"),
    ( 2, "Krittika",          "Rakshasa",   "Sheep",      "F", "Brahmin",   "Antya"),
    ( 3, "Rohini",            "Manushya",   "Serpent",    "M", "Shudra",    "Antya"),
    ( 4, "Mrigashira",        "Deva",       "Serpent",    "F", "Vaishya",   "Madhya"),
    ( 5, "Ardra",             "Manushya",   "Dog",        "F", "Mixed",     "Madhya"),
    ( 6, "Punarvasu",         "Deva",       "Cat",        "F", "Vaishya",   "Madhya"),
    ( 7, "Pushya",            "Deva",       "Sheep",      "M", "Kshatriya", "Aadi"),
    ( 8, "Ashlesha",          "Rakshasa",   "Cat",        "M", "Mixed",     "Aadi"),
    ( 9, "Magha",             "Rakshasa",   "Rat",        "M", "Shudra",    "Aadi"),
    (10, "Purva Phalguni",    "Manushya",   "Rat",        "F", "Brahmin",   "Madhya"),
    (11, "Uttara Phalguni",   "Manushya",   "Cow",        "M", "Kshatriya", "Madhya"),
    (12, "Hasta",             "Deva",       "Buffalo",    "F", "Vaishya",   "Madhya"),
    (13, "Chitra",            "Rakshasa",   "Tiger",      "F", "Mixed",     "Antya"),
    (14, "Swati",             "Deva",       "Buffalo",    "M", "Mixed",     "Antya"),
    (15, "Vishakha",          "Rakshasa",   "Tiger",      "M", "Mixed",     "Antya"),
    (16, "Anuradha",          "Deva",       "Hare",       "F", "Shudra",    "Aadi"),
    (17, "Jyeshtha",          "Rakshasa",   "Hare",       "M", "Mixed",     "Madhya"),
    (18, "Mula",              "Rakshasa",   "Dog",        "M", "Mixed",     "Aadi"),
    (19, "Purva Ashadha",     "Manushya",   "Monkey",     "F", "Brahmin",   "Madhya"),
    (20, "Uttara Ashadha",    "Manushya",   "Mongoose",   "M", "Kshatriya", "Madhya"),
    (21, "Shravana",          "Deva",       "Monkey",     "M", "Mixed",     "Antya"),
    (22, "Dhanishtha",        "Rakshasa",   "Lion",       "F", "Mixed",     "Aadi"),
    (23, "Shatabhisha",       "Rakshasa",   "Horse",      "F", "Mixed",     "Aadi"),
    (24, "Purva Bhadrapada",  "Manushya",   "Lion",       "M", "Brahmin",   "Aadi"),
    (25, "Uttara Bhadrapada", "Manushya",   "Cow",        "F", "Kshatriya", "Antya"),
    (26, "Revati",            "Deva",       "Elephant",   "F", "Shudra",    "Antya"),
]

# Build lookup by name
_BY_NAME: Dict[str, dict] = {
    row[1]: {
        "idx": row[0], "gana": row[2], "yoni": row[3],
        "yoni_gender": row[4], "varna": row[5], "nadi": row[6],
    }
    for row in _NAK_DATA
}

# ── Rasi data ─────────────────────────────────────────────────────────────────
_RASI_LORDS = {
    "Mesha": "Mars", "Vrishabha": "Venus", "Mithuna": "Mercury",
    "Karka": "Moon", "Simha": "Sun", "Kanya": "Mercury",
    "Tula": "Venus", "Vrischika": "Mars", "Dhanu": "Jupiter",
    "Makara": "Saturn", "Kumbha": "Saturn", "Meena": "Jupiter",
}

_RASI_IDX = {
    "Mesha": 0, "Vrishabha": 1, "Mithuna": 2, "Karka": 3,
    "Simha": 4, "Kanya": 5, "Tula": 6, "Vrischika": 7,
    "Dhanu": 8, "Makara": 9, "Kumbha": 10, "Meena": 11,
}

# Graha Maitri: planet friendship table
# +2 = great friend, +1 = friend, 0 = neutral, -1 = enemy, -2 = great enemy
_PLANET_FRIENDS: Dict[str, Dict[str, int]] = {
    "Sun":     {"Sun": 0, "Moon": +1, "Mars": +1, "Mercury": -1, "Venus": -1, "Jupiter": +1, "Saturn": -2},
    "Moon":    {"Sun": +1, "Moon": 0, "Mars": 0, "Mercury": +1, "Venus": 0, "Jupiter": 0, "Saturn": -1},
    "Mars":    {"Sun": +1, "Moon": 0, "Mars": 0, "Mercury": -1, "Venus": 0, "Jupiter": +1, "Saturn": -1},
    "Mercury": {"Sun": +1, "Moon": -1, "Mars": 0, "Mercury": 0, "Venus": +1, "Jupiter": 0, "Saturn": 0},
    "Venus":   {"Sun": -1, "Moon": 0, "Mars": 0, "Mercury": +1, "Venus": 0, "Jupiter": -1, "Saturn": +1},
    "Jupiter": {"Sun": +1, "Moon": +1, "Mars": +1, "Mercury": -1, "Venus": -1, "Jupiter": 0, "Saturn": -1},
    "Saturn":  {"Sun": -2, "Moon": -1, "Mars": -1, "Mercury": +1, "Venus": +1, "Jupiter": -1, "Saturn": 0},
}

# Yoni compatibility (animal pairs): friendly=3, neutral=2, enemy=0, same=4
_YONI_FRIENDLY = {
    frozenset({"Horse", "Sheep"}): 3,
    frozenset({"Elephant", "Lion"}): 0,
    frozenset({"Serpent", "Mongoose"}): 0,
    frozenset({"Dog", "Hare"}): 0,
    frozenset({"Rat", "Cat"}): 0,
    frozenset({"Cow", "Tiger"}): 0,
    frozenset({"Buffalo", "Dog"}): 0,
    frozenset({"Monkey", "Sheep"}): 3,
}

# Varna order (higher = higher varna)
_VARNA_RANK = {
    "Brahmin": 4, "Kshatriya": 3, "Vaishya": 2,
    "Shudra": 1, "Mixed": 1,
}

# Vashya groups (who controls whom)
_VASHYA_GROUPS = {
    "Mesha":    "quadruped",  "Vrishabha": "quadruped",
    "Mithuna":  "human",      "Karka":     "insect",
    "Simha":    "wild",       "Kanya":     "human",
    "Tula":     "human",      "Vrischika": "insect",
    "Dhanu":    "mixed",      "Makara":    "insect",
    "Kumbha":   "human",      "Meena":     "water",
}

_VASHYA_COMPAT = {
    ("human",    "human"):    2,
    ("quadruped","quadruped"): 2,
    ("insect",   "insect"):   2,
    ("wild",     "wild"):     2,
    ("water",    "water"):    2,
    ("human",    "quadruped"): 1,
    ("quadruped","human"):    1,
    ("human",    "insect"):   1,
    ("insect",   "human"):    1,
}


# ── Kuta scoring functions ─────────────────────────────────────────────────────

def _varna(boy_nak: str, girl_nak: str) -> Tuple[int, int]:
    """Varna kuta — max 1 pt. Girl's varna must be >= Boy's varna."""
    bv = _VARNA_RANK.get(_BY_NAME.get(boy_nak, {}).get("varna", "Mixed"), 1)
    gv = _VARNA_RANK.get(_BY_NAME.get(girl_nak, {}).get("varna", "Mixed"), 1)
    return (1 if gv >= bv else 0), 1


def _vashya(boy_rasi: str, girl_rasi: str) -> Tuple[int, int]:
    """Vashya kuta — max 2 pts."""
    bg = _VASHYA_GROUPS.get(boy_rasi, "human")
    gg = _VASHYA_GROUPS.get(girl_rasi, "human")
    score = _VASHYA_COMPAT.get((bg, gg), _VASHYA_COMPAT.get((gg, bg), 0))
    return score, 2


def _tara(boy_nak: str, girl_nak: str) -> Tuple[int, int]:
    """Tara kuta — max 3 pts. Count from girl's nak to boy's nak mod 9."""
    bi = _BY_NAME.get(boy_nak, {}).get("idx", 0)
    gi = _BY_NAME.get(girl_nak, {}).get("idx", 0)
    # Count from girl to boy
    count = ((bi - gi) % 27) % 9 + 1  # 1-9
    # Favourable tara positions: 1,2,4,6,8
    favourable = {1, 2, 4, 6, 8}
    score = 3 if count in favourable else 0
    return score, 3


def _yoni(boy_nak: str, girl_nak: str) -> Tuple[int, int]:
    """Yoni kuta — max 4 pts based on animal compatibility."""
    bd = _BY_NAME.get(boy_nak, {})
    gd = _BY_NAME.get(girl_nak, {})
    ba, bg_ = bd.get("yoni", "Horse"), bd.get("yoni_gender", "M")
    ga, gg_ = gd.get("yoni", "Horse"), gd.get("yoni_gender", "F")

    if ba == ga:
        # Same animal — same gender=4, opposite gender=3
        score = 4 if bg_ != gg_ else 3
    else:
        pair = frozenset({ba, ga})
        score = _YONI_FRIENDLY.get(pair, 2)  # default neutral=2
    return score, 4


def _graha_maitri(boy_rasi: str, girl_rasi: str) -> Tuple[int, int]:
    """Graha Maitri kuta — max 5 pts. Planetary friendship between rasi lords."""
    bl = _RASI_LORDS.get(boy_rasi, "Mars")
    gl = _RASI_LORDS.get(girl_rasi, "Mars")
    bf = _PLANET_FRIENDS.get(bl, {}).get(gl, 0)   # boy's lord views girl's lord
    gf = _PLANET_FRIENDS.get(gl, {}).get(bl, 0)   # girl's lord views boy's lord
    combined = bf + gf  # -4 to +4
    # Map combined score to 0-5
    if combined >= 3:
        score = 5
    elif combined == 2:
        score = 4
    elif combined == 1:
        score = 3
    elif combined == 0:
        score = 2
    elif combined == -1:
        score = 1
    else:
        score = 0
    return score, 5


def _gana(boy_nak: str, girl_nak: str) -> Tuple[int, int]:
    """Gana kuta — max 6 pts. Temperament compatibility."""
    bg = _BY_NAME.get(boy_nak, {}).get("gana", "Deva")
    gg = _BY_NAME.get(girl_nak, {}).get("gana", "Deva")
    table = {
        ("Deva",       "Deva"):       6,
        ("Manushya",   "Manushya"):   6,
        ("Rakshasa",   "Rakshasa"):   6,
        ("Deva",       "Manushya"):   5,
        ("Manushya",   "Deva"):       5,
        ("Manushya",   "Rakshasa"):   0,
        ("Rakshasa",   "Manushya"):   0,
        ("Deva",       "Rakshasa"):   1,
        ("Rakshasa",   "Deva"):       1,
    }
    return table.get((bg, gg), 0), 6


def _bhakoot(boy_rasi: str, girl_rasi: str) -> Tuple[int, int]:
    """
    Bhakoot kuta — max 7 pts.
    Unfavourable: 2-12, 6-8, 5-9 counted from boy to girl or girl to boy.
    """
    bi = _RASI_IDX.get(boy_rasi, 0)
    gi = _RASI_IDX.get(girl_rasi, 0)
    bg_count = (gi - bi) % 12 + 1   # 1-12 from boy to girl
    gb_count = (bi - gi) % 12 + 1   # 1-12 from girl to boy

    bad_pairs = {(2, 12), (12, 2), (6, 8), (8, 6), (5, 9), (9, 5)}
    if (bg_count, gb_count) in bad_pairs or (gb_count, bg_count) in bad_pairs:
        score = 0
    elif bg_count == 1 or gb_count == 1:   # same rasi
        score = 7
    else:
        score = 7
    return score, 7


def _nadi(boy_nak: str, girl_nak: str) -> Tuple[int, int]:
    """Nadi kuta — max 8 pts. Same nadi = 0 (major dosha), different = 8."""
    bn = _BY_NAME.get(boy_nak, {}).get("nadi", "Aadi")
    gn = _BY_NAME.get(girl_nak, {}).get("nadi", "Aadi")
    score = 0 if bn == gn else 8
    has_dosha = (bn == gn)
    return score, 8, has_dosha


# ── Main entry point ───────────────────────────────────────────────────────────

def compute_ashtakoota(
    boy_rasi: str,
    boy_nak: str,
    girl_rasi: str,
    girl_nak: str,
) -> dict:
    """
    Compute Ashtakoota Guna Milan.

    Args:
        boy_rasi:   Sanskrit moon sign of boy  (e.g. "Vrischika")
        boy_nak:    Sanskrit nakshatra of boy  (e.g. "Anuradha")
        girl_rasi:  Sanskrit moon sign of girl
        girl_nak:   Sanskrit nakshatra of girl

    Returns dict shaped like Prokerala's API response (data.total_points, data.kutas, ...)
    """
    # Normalise nakshatra names to closest match if not found
    boy_nak  = _closest_nak(boy_nak)
    girl_nak = _closest_nak(girl_nak)

    varna_s,  varna_m         = _varna(boy_nak, girl_nak)
    vashya_s, vashya_m        = _vashya(boy_rasi, girl_rasi)
    tara_s,   tara_m          = _tara(boy_nak, girl_nak)
    yoni_s,   yoni_m          = _yoni(boy_nak, girl_nak)
    gm_s,     gm_m            = _graha_maitri(boy_rasi, girl_rasi)
    gana_s,   gana_m          = _gana(boy_nak, girl_nak)
    bhak_s,   bhak_m          = _bhakoot(boy_rasi, girl_rasi)
    nadi_s,   nadi_m, n_dosha = _nadi(boy_nak, girl_nak)

    total = varna_s + vashya_s + tara_s + yoni_s + gm_s + gana_s + bhak_s + nadi_s

    return {
        "data": {
            "total_points": total,
            "max_points":   36,
            "nadi_dosha":   n_dosha,
            "kutas": [
                {"name": "Varna",        "total": varna_m,  "obtained": varna_s},
                {"name": "Vashya",       "total": vashya_m, "obtained": vashya_s},
                {"name": "Tara",         "total": tara_m,   "obtained": tara_s},
                {"name": "Yoni",         "total": yoni_m,   "obtained": yoni_s},
                {"name": "Graha Maitri", "total": gm_m,     "obtained": gm_s},
                {"name": "Gana",         "total": gana_m,   "obtained": gana_s},
                {"name": "Bhakoot",      "total": bhak_m,   "obtained": bhak_s},
                {"name": "Nadi",         "total": nadi_m,   "obtained": nadi_s},
            ],
        }
    }


def _closest_nak(name: str) -> str:
    """Return the closest matching nakshatra name (case-insensitive prefix match)."""
    if name in _BY_NAME:
        return name
    nl = name.lower()
    for k in _BY_NAME:
        if k.lower().startswith(nl[:4]):
            return k
    return "Aswini"   # absolute fallback
