"""app/core/security.py"""
import hashlib
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def _p(s: str) -> str:
    # SHA-256 → 64 hex chars → always under bcrypt 72-byte limit
    return hashlib.sha256(s.encode()).hexdigest()

def hash_password(plain: str) -> str:
    return pwd_context.hash(_p(plain))

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(_p(plain), hashed)

def _token(subject: str, delta: timedelta, extra: Dict[str,Any]={}) -> str:
    exp = datetime.now(timezone.utc) + delta
    return jwt.encode({"sub": subject, "exp": exp, **extra},
        settings.SECRET_KEY, algorithm=settings.ALGORITHM)

def create_access_token(user_id: str) -> str:
    return _token(user_id, timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES), {"type":"access"})

def create_refresh_token(user_id: str) -> str:
    return _token(user_id, timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS), {"type":"refresh"})

def decode_token(token: str) -> Optional[str]:
    try:
        return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]).get("sub")
    except JWTError:
        return None
