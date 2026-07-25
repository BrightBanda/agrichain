import asyncio
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from app.modules.farmers.models import User
from app.core.security import hash_password

DATABASE_URL = "postgresql+asyncpg://postgres:secretepassword@localhost:5432/agrichain_db"

engine = create_async_engine(DATABASE_URL, echo=True)
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


async def update_test_user_password():
    async with AsyncSessionLocal() as session:
        # Update existing user's password
        result = await session.execute(
            update(User)
            .where(User.phone_number == "1234")
            .values(password_hash=hash_password("123456"))
        )
        await session.commit()
        
        if result.rowcount > 0:
            print("Password updated successfully!")
            print("Phone: 1234")
            print("New Password: 123456")
        else:
            print("User not found!")


if __name__ == "__main__":
    asyncio.run(update_test_user_password())
