"""
core/http_client.py
Centralised async HTTP client.
ALL external API calls must go through this module — never use httpx/requests directly.

Usage:
    from app.core.http_client import http_client
    data = await http_client.get("https://api.example.com/endpoint", params={...})
"""
import logging
from typing import Any, Dict, Optional

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

# ── Timeouts ─────────────────────────────────────────────────────────────────
DEFAULT_TIMEOUT = httpx.Timeout(
    connect=5.0,
    read=30.0,
    write=10.0,
    pool=5.0,
)


class HttpClient:
    """
    Singleton async HTTP client wrapping httpx.AsyncClient.
    Provides:
      - Automatic retries (3x with exponential backoff)
      - Structured logging of every request/response
      - Standardised error raising
    """

    def __init__(self) -> None:
        self._client: Optional[httpx.AsyncClient] = None

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(
                timeout=DEFAULT_TIMEOUT,
                follow_redirects=True,
                headers={"User-Agent": f"{settings.APP_NAME}/{settings.APP_VERSION}"},
            )
        return self._client

    async def _request(
        self,
        method: str,
        url: str,
        *,
        headers: Optional[Dict[str, str]] = None,
        params: Optional[Dict[str, Any]] = None,
        json: Optional[Dict[str, Any]] = None,
        data: Optional[Dict[str, Any]] = None,
        retries: int = 3,
    ) -> Dict[str, Any]:
        client = await self._get_client()
        attempt = 0
        last_error: Optional[Exception] = None

        while attempt < retries:
            attempt += 1
            try:
                logger.debug(f"[HTTP] {method} {url} | attempt={attempt}")
                response = await client.request(
                    method,
                    url,
                    headers=headers,
                    params=params,
                    json=json,
                    data=data,
                )
                response.raise_for_status()
                logger.debug(f"[HTTP] {response.status_code} ← {url}")
                return response.json()

            except httpx.HTTPStatusError as e:
                logger.error(
                    f"[HTTP] Status {e.response.status_code} for {url}: {e.response.text[:200]}"
                )
                raise ExternalAPIError(
                    url=url,
                    status_code=e.response.status_code,
                    detail=e.response.text[:500],
                ) from e

            except httpx.RequestError as e:
                logger.warning(f"[HTTP] Request error (attempt {attempt}): {e}")
                last_error = e
                if attempt >= retries:
                    break
                import asyncio
                await asyncio.sleep(2 ** (attempt - 1))  # exponential backoff

        raise ExternalAPIError(
            url=url,
            status_code=503,
            detail=str(last_error),
        )

    async def get(self, url: str, **kwargs) -> Dict[str, Any]:
        return await self._request("GET", url, **kwargs)

    async def post(self, url: str, **kwargs) -> Dict[str, Any]:
        return await self._request("POST", url, **kwargs)

    async def put(self, url: str, **kwargs) -> Dict[str, Any]:
        return await self._request("PUT", url, **kwargs)

    async def delete(self, url: str, **kwargs) -> Dict[str, Any]:
        return await self._request("DELETE", url, **kwargs)

    async def close(self) -> None:
        if self._client and not self._client.is_closed:
            await self._client.aclose()
            logger.info("[HTTP] Client closed")


class ExternalAPIError(Exception):
    """Raised when an external API call fails."""

    def __init__(self, url: str, status_code: int, detail: str) -> None:
        self.url = url
        self.status_code = status_code
        self.detail = detail
        super().__init__(f"External API error [{status_code}] at {url}: {detail}")


# Singleton instance — import this everywhere
http_client = HttpClient()
