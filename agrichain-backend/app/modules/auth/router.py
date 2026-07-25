from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import hash_password
from app.modules.farmers.models import User, Farmer, UserRole
from app.modules.auth.schemas import FarmerRegisterRequest, UserRegisterResponse

router = APIRouter()


@router.post(
    "/register/farmer",
    response_model=UserRegisterResponse,
    status_code=status.HTTP_201_CREATED,
)
async def register_farmer(
    payload: FarmerRegisterRequest, db: AsyncSession = Depends(get_db)
):
    """FR-01: Registers a new Farmer with identity details and KYC documentation references."""

    # 1. Check if Phone Number already exists
    existing_phone = await db.execute(
        select(User).where(User.phone_number == payload.phone_number)
    )
    if existing_phone.scalars().first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this phone number is already registered.",
        )

    # 2. Check if National ID already exists
    existing_id = await db.execute(
        select(Farmer).where(Farmer.national_id_number == payload.national_id_number)
    )
    if existing_id.scalars().first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A farmer with this National ID number is already registered.",
        )

    # 3. Create User record
    new_user = User(
        phone_number=payload.phone_number,
        password_hash=hash_password(payload.password),
        role=UserRole.FARMER,
        is_verified=False,
    )
    db.add(new_user)
    await db.flush()  # Populates new_user.id

    # 4. Create Farmer Profile record
    farmer_profile = Farmer(
        user_id=new_user.id,
        full_name=payload.full_name,
        national_id_number=payload.national_id_number,
        gender=payload.gender,
        district=payload.district,
        traditional_authority=payload.traditional_authority,
        village=payload.village,
        profile_photo_url=payload.profile_photo_url,
        id_front_photo_url=payload.id_front_photo_url,
        id_back_photo_url=payload.id_back_photo_url,
    )
    db.add(farmer_profile)

    await db.commit()
    await db.refresh(new_user)

    # Fetch relations for response payload
    result = await db.execute(select(User).where(User.id == new_user.id))
    return result.scalars().first()
