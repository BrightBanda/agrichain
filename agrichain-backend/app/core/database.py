from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings

# Create async database engine
engine = create_async_engine(
    settings.DATABASE_URL,
    # Echo prints every statement *with its bound parameters*, which includes
    # password hashes and personal data, so it follows DEBUG rather than being
    # left on.
    echo=settings.DEBUG,
    future=True,
)

# Create session factory
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


# Base class for SQLAlchemy ORM models
class Base(DeclarativeBase):
    pass


# Dependency to inject DB session into API routes
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
