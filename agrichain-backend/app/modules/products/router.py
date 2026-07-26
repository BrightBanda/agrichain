from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.deps import get_current_user
from app.modules.blockchain import canonical, service as ledger
from app.modules.blockchain.events import LedgerEntity, LedgerEvent
from app.modules.farmers.models import User, UserRole
from app.modules.products.models import FARM_PRODUCE_TYPES, Product, ProductType
from app.modules.suppliers.models import SupplierProfile
from app.modules.products.schemas import (
    ProductCreateRequest,
    ProductListResponse,
    ProductResponse,
)

router = APIRouter()

# ProductResponse exposes seller_name and seller_verified, which read
# Product.user and its farmer profile. Both must be eager-loaded or serialising
# the response raises MissingGreenlet under asyncio.
_WITH_SELLER = selectinload(Product.user).selectinload(User.farmer_profile)


async def _load_product(db: AsyncSession, product_id) -> Product | None:
    result = await db.execute(
        select(Product).options(_WITH_SELLER).where(Product.id == product_id)
    )
    return result.scalars().first()


async def _assert_may_list(
    db: AsyncSession, user: User, product_type: ProductType
) -> None:
    """Reject a listing the caller's role is not entitled to publish."""
    if user.role is UserRole.FARMER:
        if product_type not in FARM_PRODUCE_TYPES:
            allowed = ", ".join(sorted(t.value for t in FARM_PRODUCE_TYPES))
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    f"Farmers may list {allowed}. Agricultural inputs are "
                    f"listed by registered service providers."
                ),
            )
        return

    if user.role is UserRole.SUPPLIER:
        profile = (
            await db.execute(
                select(SupplierProfile).where(SupplierProfile.user_id == user.id)
            )
        ).scalars().first()

        if profile is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Your service provider profile is missing.",
            )
        if not profile.may_list(product_type):
            declared = ", ".join(profile.services) or "none"
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    f"You did not register {product_type.value} as one of your "
                    f"services. You offer: {declared}."
                ),
            )
        return

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail=(
            f"{user.role.value} accounts cannot list products. Register as a "
            f"farmer or a service provider."
        ),
    )


@router.post(
    "/products",
    response_model=ProductResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_product(
    payload: ProductCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new product listing.

    Who may list what is enforced here, not just in the app: a farmer sells
    produce and livestock, a service provider sells only the inputs it declared
    at registration (FR-11).
    """
    await _assert_may_list(db, current_user, payload.product_type)

    new_product = Product(
        user_id=current_user.id,
        product_type=payload.product_type,
        product_name=payload.product_name,
        unit_type=payload.unit_type,
        district=payload.district,
        price_per_unit=payload.price_per_unit,
        quantity_available=payload.quantity_available,
        description=payload.description,
    )
    db.add(new_product)
    await db.flush()

    # A produce listing is market activity the credit engine counts, so it is
    # anchored (FR-23) and the listing and its block commit together.
    await ledger.append_event(
        db,
        event_type=LedgerEvent.PRODUCE_LISTED,
        entity_type=LedgerEntity.PRODUCT,
        entity_id=new_product.id,
        payload=canonical.product_payload(new_product),
        summary={
            "product_name": new_product.product_name,
            "product_type": new_product.product_type.value,
            "district": new_product.district,
            "quantity_available": new_product.quantity_available,
        },
    )

    await db.commit()
    return await _load_product(db, new_product.id)


@router.get("/products", response_model=ProductListResponse)
async def get_all_products(db: AsyncSession = Depends(get_db)):
    """Get all products, newest first, with their seller details."""
    result = await db.execute(
        select(Product).options(_WITH_SELLER).order_by(Product.created_at.desc())
    )
    products = list(result.scalars().all())
    return ProductListResponse(products=products, total=len(products))
