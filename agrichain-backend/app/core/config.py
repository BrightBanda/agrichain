from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application configuration, loaded from the environment.

    DATABASE_URL and SECRET_KEY deliberately have **no defaults**. A missing
    value fails startup loudly instead of silently falling back to a shared
    development credential — which is how a placeholder key ends up in
    production signing real tokens.
    """

    PROJECT_NAME: str = "AgriChain Backend API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"

    # Also gates the ledger tamper-demo endpoints; must be false in production.
    DEBUG: bool = False

    # Database Configuration
    DATABASE_URL: str

    # The same database with the sync driver, for the standalone maintenance
    # scripts that use asyncpg directly. Derived from DATABASE_URL when unset.
    DATABASE_URL_SYNC: str = ""

    # JWT Authentication Settings
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 Days

    # Comma-separated origins, or "*" for any.
    BACKEND_CORS_ORIGINS: str = "*"

    # Password used by seed_demo.py for the accounts it creates.
    DEMO_ACCOUNT_PASSWORD: str = "Password123!"

    model_config = SettingsConfigDict(env_file=".env", case_sensitive=True)

    @field_validator("SECRET_KEY")
    @classmethod
    def reject_placeholder_secret(cls, value: str) -> str:
        """Refuse to start on a key that was never changed from the template."""
        if len(value) < 32:
            raise ValueError(
                "SECRET_KEY must be at least 32 characters. Generate one with: "
                'python -c "import secrets; print(secrets.token_hex(32))"'
            )
        lowered = value.lower()
        if "change_me" in lowered or "your-super-secret" in lowered:
            raise ValueError(
                "SECRET_KEY is still the placeholder from .env.example. "
                "Generate a real one before starting the server."
            )
        return value

    @property
    def cors_origins(self) -> list[str]:
        """BACKEND_CORS_ORIGINS parsed into the list CORSMiddleware expects."""
        raw = self.BACKEND_CORS_ORIGINS.strip()
        if raw in ("", "*"):
            return ["*"]
        return [origin.strip() for origin in raw.split(",") if origin.strip()]

    @property
    def sync_database_url(self) -> str:
        """The database URL with the async driver stripped, for asyncpg scripts."""
        if self.DATABASE_URL_SYNC:
            return self.DATABASE_URL_SYNC
        return self.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")


settings = Settings()
