"""Application configuration using pydantic-settings."""

import os
from pydantic_settings import BaseSettings
from typing import Optional

_BASE_DIR = os.path.dirname(os.path.abspath(__file__))


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    DATABASE_URL: str = f"sqlite:///{os.path.join(_BASE_DIR, 'salah_tracker.db')}"
    FIREBASE_CREDENTIALS_PATH: Optional[str] = None
    CORS_ORIGINS: str = "*"

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
