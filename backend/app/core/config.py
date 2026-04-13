"""
core/config.py
Centralised, type-safe application configuration via Pydantic Settings.
All values are read from environment variables / .env file.
"""
from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # ── App ──────────────────────────────────────────────
    APP_NAME: str = "JyotishAI"
    APP_ENV: str = "development"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    ALLOWED_ORIGINS: str = "*"

    @property
    def origins_list(self) -> List[str]:
        return [o.strip() for o in self.ALLOWED_ORIGINS.split(",")]

    # ── Security ─────────────────────────────────────────
    SECRET_KEY: str = "CHANGE_ME_use_openssl_rand_hex_32"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    ALGORITHM: str = "HS256"

    # ── Firebase ─────────────────────────────────────────
    FIREBASE_PROJECT_ID: str = "jyotish-ai"
    FIREBASE_CREDENTIALS_JSON: str = "./firebase-credentials.json"

    # ── Astrology APIs ────────────────────────────────────
    PROKERALA_CLIENT_ID: str = ""
    PROKERALA_CLIENT_SECRET: str = ""
    PROKERALA_BASE_URL: str = "https://api.prokerala.com/v2/astrology"

    ASTROAPI_KEY: str = ""
    ASTROAPI_BASE_URL: str = "https://json.astrologyapi.com/v1"

    # ── AI ────────────────────────────────────────────────
    OPENAI_API_KEY: str = ""
    OPENAI_MODEL: str = "gpt-4o-mini"

    # ── Payments ─────────────────────────────────────────
    RAZORPAY_KEY_ID: str = ""
    RAZORPAY_KEY_SECRET: str = ""

    # ── Rate Limiting ─────────────────────────────────────
    RATE_LIMIT_PER_MINUTE: int = 60
    RATE_LIMIT_AI_PER_MINUTE: int = 10

    @property
    def is_production(self) -> bool:
        return self.APP_ENV == "production"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
