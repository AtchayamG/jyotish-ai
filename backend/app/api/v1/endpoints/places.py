"""
app/api/v1/endpoints/places.py
Proxy for place autocomplete + details using OpenStreetMap Nominatim.
  - Completely free, no API key, no billing required.
  - Rate limit: 1 req/sec (fine for user-typing scenarios; we cache nothing).
  - For timezone we use timezonefinder (pure-Python, no external API).
"""
import logging
import httpx
from fastapi import APIRouter, Query, HTTPException

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/places", tags=["places"])

_NOMINATIM = "https://nominatim.openstreetmap.org"
_HEADERS = {
    # Nominatim requires a descriptive User-Agent
    "User-Agent": "JyotishAI/1.0 (contact: atchayamganesh@gmail.com)",
    "Accept-Language": "en",
}


async def _get(url: str, params: dict) -> list | dict:
    async with httpx.AsyncClient(timeout=12, headers=_HEADERS) as client:
        r = await client.get(url, params=params)
        r.raise_for_status()
        return r.json()


# ── Health check ───────────────────────────────────────────────────────────────

@router.get("/ping")
async def places_ping():
    """Health check — Nominatim needs no key."""
    return {"provider": "OpenStreetMap Nominatim", "key_required": False, "status": "ok"}


# ── Autocomplete ───────────────────────────────────────────────────────────────

@router.get("/autocomplete")
async def autocomplete(q: str = Query(..., min_length=2)):
    """
    City autocomplete via Nominatim search.
    Returns up to 5 predictions: {description, place_id}.
    place_id is the Nominatim OSM place_id (integer, returned as string).
    """
    try:
        results = await _get(
            f"{_NOMINATIM}/search",
            {
                "q": q,
                "format": "jsonv2",
                "addressdetails": 1,
                "limit": 8,
                "featuretype": "city",   # prefer city-level results
            },
        )
    except httpx.HTTPError as e:
        logger.error("Nominatim autocomplete HTTP error: %s", e)
        raise HTTPException(502, f"Nominatim unreachable: {e}")
    except Exception as e:
        logger.error("Nominatim autocomplete error: %s", e, exc_info=True)
        raise HTTPException(500, f"Internal error: {type(e).__name__}: {e}")

    if not results:
        return []

    seen: set[str] = set()
    predictions = []
    for r in results:
        addr = r.get("address", {})
        # Build a human-readable city label
        city  = addr.get("city") or addr.get("town") or addr.get("village") or r.get("name", "")
        state = addr.get("state", "")
        country = addr.get("country", "")
        parts = [p for p in [city, state, country] if p]
        description = ", ".join(parts) if parts else r.get("display_name", "")

        if description in seen:
            continue
        seen.add(description)

        predictions.append({
            "description": description,
            "place_id": str(r["place_id"]),
        })
        if len(predictions) >= 5:
            break

    return predictions


# ── Details ────────────────────────────────────────────────────────────────────

@router.get("/details")
async def place_details(place_id: str = Query(...)):
    """
    Fetch lat/lng + UTC-offset timezone for a Nominatim place_id.
    Timezone is computed locally via timezonefinder — no extra API call.
    """
    try:
        data = await _get(
            f"{_NOMINATIM}/details",
            {"place_id": place_id, "format": "json", "addressdetails": 1},
        )
    except httpx.HTTPError as e:
        raise HTTPException(502, f"Nominatim unreachable: {e}")
    except Exception as e:
        logger.error("Nominatim details error: %s", e, exc_info=True)
        raise HTTPException(500, f"Internal error: {type(e).__name__}: {e}")

    if not data or "centroid" not in data:
        raise HTTPException(404, f"place_id not found: {place_id}")

    centroid = data["centroid"]["coordinates"]   # [lon, lat]
    lng = float(centroid[0])
    lat = float(centroid[1])

    addr = data.get("address", {})
    name_parts = [
        addr.get("localname") or data.get("localname") or data.get("name", ""),
        addr.get("state", ""),
        addr.get("country", ""),
    ]
    name = ", ".join(p for p in name_parts if p) or data.get("localname", "")

    # Compute UTC offset using timezonefinder (pure-Python, no network call)
    tz_hours = _get_tz_offset(lat, lng)

    return {"name": name, "latitude": lat, "longitude": lng, "timezone": tz_hours}


def _get_tz_offset(lat: float, lng: float) -> float:
    """Return UTC offset in hours for lat/lng using timezonefinder. Falls back to 5.5 (IST)."""
    try:
        from timezonefinder import TimezoneFinder
        import pytz
        from datetime import datetime
        tf = TimezoneFinder()
        tz_name = tf.timezone_at(lat=lat, lng=lng)
        if tz_name:
            tz = pytz.timezone(tz_name)
            offset = tz.utcoffset(datetime.utcnow())
            return offset.total_seconds() / 3600
    except Exception as e:
        logger.warning("timezonefinder failed (%s) — using default 5.5", e)
    return 5.5
