import uuid
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.config import settings
from app.core.database import get_db
from app.modules.farmers.models import User, UserRole

# HTTP Bearer scheme for token authentication
oauth2_scheme = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    token = credentials.credentials
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    # A malformed subject is a bad token, not a server error.
    try:
        subject = uuid.UUID(user_id)
    except ValueError:
        raise credentials_exception

    # Query database for user
    result = await db.execute(select(User).where(User.id == subject))
    user = result.scalars().first()

    if user is None:
        raise credentials_exception
    return user


def require_roles(*allowed: UserRole):
    """Dependency factory restricting an endpoint to certain roles.

    The role already travels inside the JWT, but it is re-read from the user
    record here so a role change takes effect without waiting for the token to
    expire.
    """

    async def dependency(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in allowed:
            allowed_names = ", ".join(role.value for role in allowed)
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    f"This action requires one of the following roles: "
                    f"{allowed_names}."
                ),
            )
        return current_user

    return dependency
