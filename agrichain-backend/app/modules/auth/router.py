from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.security import hash_password, verify_password, create_access_token
from app.modules.blockchain import canonical, service as ledger
from app.modules.blockchain.events import LedgerEntity, LedgerEvent
from app.modules.farmers.models import User, Farmer, UserRole
from app.modules.auth.schemas import (
    FarmerRegisterRequest,
    OrganizationRegisterRequest,
    UserRegisterResponse,
    UserListResponse,
    LoginRequest,
    LoginResponse,
)

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
    await db.flush()  # Populates farmer_profile.id

    # Anchor the KYC record so a lender can later confirm the identity details
    # behind a lending score were never edited (FR-23). Only the hash goes on
    # the ledger; the summary deliberately carries no personal data (NFR-02).
    await ledger.append_event(
        db,
        event_type=LedgerEvent.FARMER_REGISTERED,
        entity_type=LedgerEntity.FARMER,
        entity_id=farmer_profile.id,
        payload=canonical.farmer_payload(farmer_profile),
        summary={
            "district": farmer_profile.district,
            "traditional_authority": farmer_profile.traditional_authority,
        },
    )

    await db.commit()

    # selectinload is required, not an optimisation: the response model reads
    # farmer_profile while serialising, and a lazy load at that point raises
    # MissingGreenlet under asyncio.
    result = await db.execute(
        select(User)
        .options(selectinload(User.farmer_profile))
        .where(User.id == new_user.id)
    )
    return result.scalars().first()


@router.post(
    "/register/organization",
    response_model=UserRegisterResponse,
    status_code=status.HTTP_201_CREATED,
)
async def register_organization(
    payload: OrganizationRegisterRequest, db: AsyncSession = Depends(get_db)
):
    """FR-01: registers an institution, supplier, buyer or cooperative."""
    existing = await db.execute(
        select(User).where(User.phone_number == payload.phone_number)
    )
    if existing.scalars().first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this phone number is already registered.",
        )

    institution = User(
        phone_number=payload.phone_number,
        email=payload.email,
        display_name=payload.display_name,
        password_hash=hash_password(payload.password),
        role=payload.role,
        is_verified=False,
    )
    db.add(institution)
    await db.commit()

    result = await db.execute(
        select(User)
        .options(selectinload(User.farmer_profile))
        .where(User.id == institution.id)
    )
    return result.scalars().first()


@router.get("/users", response_model=UserListResponse)
async def get_all_users(db: AsyncSession = Depends(get_db)):
    """Get all registered users."""
    result = await db.execute(select(User).options(selectinload(User.farmer_profile)))
    users = result.scalars().all()
    return UserListResponse(users=users, total=len(users))


@router.post("/login", response_model=LoginResponse)
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db)):
    """Authenticate user with phone number and password."""
    # Find user by phone number
    result = await db.execute(
        select(User)
        .options(selectinload(User.farmer_profile))
        .where(User.phone_number == payload.phone_number)
    )
    user = result.scalars().first()

    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid phone number or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Create access token
    access_token = create_access_token(subject=str(user.id), role=user.role.value)

    return LoginResponse(access_token=access_token, token_type="bearer", user=user)
