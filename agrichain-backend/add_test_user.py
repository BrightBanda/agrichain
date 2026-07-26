import asyncio
from datetime import datetime

from app.core.config import settings
from app.core.security import hash_password
from app.modules.farmers.models import Farmer, Gender, UserRole, User
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

# Database connection comes from .env — never hardcode credentials here.
engine = create_async_engine(settings.DATABASE_URL, echo=settings.DEBUG)
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


async def add_test_user():
    async with AsyncSessionLocal() as session:
        # Check if user already exists
        existing_user = await session.execute(
            select(User).where(User.phone_number == "1234")
        )
        if existing_user.scalars().first():
            print("User with phone number 1234 already exists!")
            return

        # Create User record
        new_user = User(
            phone_number="1234",
            password_hash=hash_password("12"),
            role=UserRole.FARMER,
            is_verified=True,
            created_at=datetime.utcnow(),
        )
        session.add(new_user)
        await session.flush()  # Populates new_user.id

        # Create Farmer Profile record with random data
        farmer_profile = Farmer(
            user_id=new_user.id,
            full_name="mosh mosh",
            national_id_number="TEST12345678ABCD",
            gender=Gender.MALE,
            district="Test District",
            traditional_authority="Test Authority",
            village="Test Village",
            profile_photo_url=None,
            id_front_photo_url=None,
            id_back_photo_url=None,
        )
        session.add(farmer_profile)

        await session.commit()
        await session.refresh(new_user)

        print("Test user created successfully!")
        print("Phone: 1234")
        print("Password: 123456")
        print(f"User ID: {new_user.id}")
        print("Full Name: mosh mosh")


if __name__ == "__main__":
    asyncio.run(add_test_user())
