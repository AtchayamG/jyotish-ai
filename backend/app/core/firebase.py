"""
app/core/firebase.py
DEFINITIVE FIX — Python 3.11 + google-cloud-firestore 2.x
Key fixes:
  1. asyncio.get_running_loop() replaces deprecated get_event_loop()
  2. FieldFilter API for Firestore SDK 2.x queries
  3. Proper error propagation
"""
import json
import logging
import os
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)
_db = None


def init_firebase() -> None:
    global _db
    try:
        import firebase_admin
        from firebase_admin import credentials, firestore
        from app.core.config import settings

        if firebase_admin._apps:
            _db = firestore.client()
            logger.info("Firebase: reusing existing app")
            return

        cred = None
        json_content = os.getenv("FIREBASE_CREDENTIALS_JSON_CONTENT", "").strip()

        if json_content:
            cred = credentials.Certificate(json.loads(json_content))
            logger.info("Firebase: loaded credentials from FIREBASE_CREDENTIALS_JSON_CONTENT env var")
        elif os.path.exists(settings.FIREBASE_CREDENTIALS_JSON):
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_JSON)
            logger.info(f"Firebase: loaded credentials from file {settings.FIREBASE_CREDENTIALS_JSON}")

        if cred is None:
            logger.warning("Firebase: no credentials found — Firestore unavailable")
            return

        firebase_admin.initialize_app(cred, {"projectId": settings.FIREBASE_PROJECT_ID})
        _db = firestore.client()
        logger.info("✓ Firebase initialised successfully")

    except Exception as e:
        logger.error(f"Firebase init FAILED: {e}")
        raise  # Must raise — startup should fail visibly if Firebase broken


def get_db():
    if _db is None:
        raise RuntimeError(
            "Firestore is not initialised. "
            "Check that FIREBASE_CREDENTIALS_JSON_CONTENT is set in Render env vars."
        )
    return _db


def _make_where_query(collection, field: str, op: str, value: Any):
    """
    Compatible wrapper for Firestore .where() query.
    google-cloud-firestore >= 2.11 requires FieldFilter;
    older versions use positional args.
    """
    try:
        from google.cloud.firestore_v1.base_query import FieldFilter
        return collection.where(filter=FieldFilter(field, op, value))
    except ImportError:
        # Fallback for older SDK versions
        return collection.where(field, op, value)


class FirestoreCollection:
    """
    Async-compatible wrapper around a Firestore collection.
    Firestore SDK is synchronous — all ops run in a thread pool executor.
    """

    def __init__(self, name: str) -> None:
        self.name = name

    def _col(self):
        return get_db().collection(self.name)

    async def _run(self, fn):
        """Run a synchronous Firestore call in the event loop's thread pool."""
        import asyncio
        # CRITICAL: get_running_loop() — get_event_loop() is deprecated in Python 3.11
        loop = asyncio.get_running_loop()
        return await loop.run_in_executor(None, fn)

    async def get_by_id(self, doc_id: str) -> Optional[Dict[str, Any]]:
        doc = await self._run(lambda: self._col().document(doc_id).get())
        if doc.exists:
            return {"id": doc.id, **doc.to_dict()}
        return None

    async def get_where(
        self, field: str, op: str, value: Any, limit: int = 50
    ) -> List[Dict[str, Any]]:
        def _query():
            q = _make_where_query(self._col(), field, op, value)
            return list(q.limit(limit).stream())
        docs = await self._run(_query)
        return [{"id": d.id, **d.to_dict()} for d in docs]

    async def list_all(self, limit: int = 500) -> List[Dict[str, Any]]:
        docs = await self._run(lambda: list(self._col().limit(limit).stream()))
        return [{"id": d.id, **d.to_dict()} for d in docs]

    async def create(self, doc_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        from datetime import datetime, timezone
        now = datetime.now(timezone.utc).isoformat()
        data.setdefault("created_at", now)
        data.setdefault("updated_at", now)
        await self._run(lambda: self._col().document(doc_id).set(data))
        return {"id": doc_id, **data}

    async def update(self, doc_id: str, data: Dict[str, Any]) -> None:
        from datetime import datetime, timezone
        data["updated_at"] = datetime.now(timezone.utc).isoformat()
        await self._run(lambda: self._col().document(doc_id).update(data))

    async def delete(self, doc_id: str) -> None:
        await self._run(lambda: self._col().document(doc_id).delete())

    async def count(self) -> int:
        docs = await self._run(lambda: list(self._col().stream()))
        return len(docs)
