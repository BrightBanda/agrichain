from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

# libpq query parameters that asyncpg does not accept. SQLAlchemy forwards
# unknown parameters straight to the driver, which then raises TypeError, so they
# are stripped instead. asyncpg negotiates TLS on its own (ssl defaults to
# "prefer"), which satisfies managed providers that require SSL.
_LIBPQ_ONLY_PARAMS = frozenset(
    {"sslmode", "channel_binding", "gssencmode", "target_session_attrs"}
)


def normalise_async_database_url(url: str) -> str:
    """Turn any Postgres URL into one the asyncpg driver accepts.

    Managed hosts (Render, Heroku, Railway) hand out `postgres://` or
    `postgresql://` URLs, often with `?sslmode=require`. Pasting one of those
    verbatim would fail at connect time, so it is rewritten here rather than
    becoming a deployment mystery.
    """
    url = url.strip()
    if not url:
        return url

    for prefix in ("postgresql+asyncpg://", "postgres://", "postgresql://"):
        if url.startswith(prefix):
            if prefix != "postgresql+asyncpg://":
                url = f"postgresql+asyncpg://{url[len(prefix):]}"
            break

    parts = urlsplit(url)
    if parts.query:
        kept = [
            (key, value)
            for key, value in parse_qsl(parts.query, keep_blank_values=True)
            if key.lower() not in _LIBPQ_ONLY_PARAMS
        ]
        url = urlunsplit(parts._replace(query=urlencode(kept)))

    return url


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

    # JWT Authentication Settings
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 Days

    # Comma-separated origins, or "*" for any.
    BACKEND_CORS_ORIGINS: str = "*"

    # Password used by seed_demo.py for the accounts it creates.
    DEMO_ACCOUNT_PASSWORD: str = "Password123!"

    model_config = SettingsConfigDict(
        env_file=".env", case_sensitive=True, extra="ignore"
    )

    @field_validator("DATABASE_URL")
    @classmethod
    def coerce_async_driver(cls, value: str) -> str:
        return normalise_async_database_url(value)

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
        """The same database, with the async driver stripped for asyncpg scripts.

        Always derived from DATABASE_URL rather than configured separately. A
        second setting would let the two drift: overriding DATABASE_URL to point
        at a deployed database while a stale sync URL still pointed at localhost
        would send writes to one database and deletes to another.
        """
        return self.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://", 1)


settings = Settings()
