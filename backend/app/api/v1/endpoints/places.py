"""
app/api/v1/endpoints/places.py
Proxy for Google Places API — avoids CORS issues when calling from Flutter Web.
Requires GOOGLE_MAPS_API_KEY env var on the backend (Render dashboard).
"""
import os
import time
import logging
import httpx
from fastapi import APIRouter, Query, HTTPException

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/places", tags=["places"])

_BASE = "https://maps.googleapis.com/maps/api"


def _get_key() -> str:
    key = os.environ.get("GOOGLE_MAPS_API_KEY", "").strip()
    if not key:
        raise HTTPException(503, "GOOGLE_MAPS_API_KEY not configured on server")
    return key


async def _get(url: str, params: dict) -> dict:
    async with httpx.AsyncClient(timeout=12) as client:
        r = await client.get(url, params=params)
        r.raise_for_status()
        return r.json()


@router.get("/autocomplete")
async def autocomplete(q: str = Query(..., min_length=2)):
    """Proxy for Places Autocomplete — returns up to 5 city predictions."""
    key = _get_key()
    try:
        data = await _get(
            f"{_BASE}/place/autocomplete/json",
            {"input": q, "key": key, "types": "(cities)", "language": "en"},
        )
    except httpx.HTTPError as e:
        logger.error("Places autocomplete HTTP error: %s", e)
        raise HTTPException(502, f"Google API unreachable: {e}")

    status = data.get("status", "UNKNOWN")
    if status == "ZERO_RESULTS":
        return []
    if status != "OK":
        logger.error("Places autocomplete error status: %s | %s", status, data.get("error_message", ""))
        raise HTTPException(502, f"Google Places error: {status} — {data.get('error_message', '')}")

    return [
        {"description": p["description"], "place_id": p["place_id"]}
        for p in data.get("predictions", [])[:5]
    ]


@router.get("/details")
async def place_details(place_id: str = Query(...)):
    """Proxy for Place Details + Timezone — returns lat, lng, timezone offset."""
    key = _get_key()

    # 1. Geometry
    try:
        details = await _get(
            f"{_BASE}/place/details/json",
            {"place_id": place_id, "fields": "name,geometry", "key": key},
        )
    except httpx.HTTPError as e:
        raise HTTPException(502, f"Google API unreachable: {e}")

    if details.get("status") != "OK":
        raise HTTPException(502, f"Place details error: {details.get('status')} — {details.get('error_message', '')}")

    result = details["result"]
    loc = result["geometry"]["location"]
    lat, lng = loc["lat"], loc["lng"]
    name = result.get("name", "")

    # 2. Timezone (best-effort — fall back to 5.5 IST if API not enabled)
    tz_hours = 5.5
    try:
        ts = int(time.time())
        tz_data = await _get(
            f"{_BASE}/timezone/json",
            {"location": f"{lat},{lng}", "timestamp": ts, "key": key},
        )
        if tz_data.get("status") == "OK":
            raw_offset = tz_data.get("rawOffset", 0)
            dst_offset = tz_data.get("dstOffset", 0)
            tz_hours = (raw_offset + dst_offset) / 3600
        else:
            logger.warning("Timezone API status: %s — using default 5.5", tz_data.get("status"))
    except Exception as e:
        logger.warning("Timezone API failed (%s) — using default 5.5", e)

    return {"name": name, "latitude": lat, "longitude": lng, "timezone": tz_hours}
