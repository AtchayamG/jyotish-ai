"""
app/api/v1/endpoints/places.py
Proxy for Google Places API — avoids CORS issues when calling from Flutter Web.
Requires GOOGLE_MAPS_API_KEY env var on the backend (Render dashboard).
"""
import os
import time
import httpx
from fastapi import APIRouter, Query, HTTPException

router = APIRouter(prefix="/places", tags=["places"])

MAPS_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "")
_BASE = "https://maps.googleapis.com/maps/api"


async def _get(url: str, params: dict) -> dict:
    """Shared async GET helper."""
    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.get(url, params=params)
        r.raise_for_status()
        return r.json()


@router.get("/autocomplete")
async def autocomplete(input: str = Query(..., min_length=2)):
    """Proxy for Places Autocomplete — returns up to 5 city predictions."""
    if not MAPS_KEY:
        raise HTTPException(503, "Google Maps API key not configured on server")
    data = await _get(
        f"{_BASE}/place/autocomplete/json",
        {"input": input, "key": MAPS_KEY, "types": "(cities)", "language": "en"},
    )
    status = data.get("status", "")
    if status not in ("OK", "ZERO_RESULTS"):
        raise HTTPException(502, f"Places API error: {status}")
    predictions = data.get("predictions", [])[:5]
    return [
        {"description": p["description"], "place_id": p["place_id"]}
        for p in predictions
    ]


@router.get("/details")
async def place_details(place_id: str = Query(...)):
    """Proxy for Place Details + Timezone — returns lat, lng, timezone offset."""
    if not MAPS_KEY:
        raise HTTPException(503, "Google Maps API key not configured on server")

    # 1. Geometry
    details = await _get(
        f"{_BASE}/place/details/json",
        {"place_id": place_id, "fields": "name,geometry", "key": MAPS_KEY},
    )
    if details.get("status") != "OK":
        raise HTTPException(502, f"Place details error: {details.get('status')}")
    result = details["result"]
    loc = result["geometry"]["location"]
    lat, lng = loc["lat"], loc["lng"]
    name = result.get("name", "")

    # 2. Timezone
    ts = int(time.time())
    tz_data = await _get(
        f"{_BASE}/timezone/json",
        {"location": f"{lat},{lng}", "timestamp": ts, "key": MAPS_KEY},
    )
    raw_offset = tz_data.get("rawOffset", 0)
    dst_offset = tz_data.get("dstOffset", 0)
    tz_hours = (raw_offset + dst_offset) / 3600

    return {"name": name, "latitude": lat, "longitude": lng, "timezone": tz_hours}
