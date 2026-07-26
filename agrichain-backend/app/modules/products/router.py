from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user
from app.modules.blockchain import canonical, service as ledger
from app.modules.blockchain.events import LedgerEntity, LedgerEvent
from app.modules.farmers.models import User
from app.modules.products.models import Product
from app.modules.products.schemas import (
    ProductCreateRequest,
    ProductListResponse,
    ProductResponse,
)

router = APIRouter()


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
    """Create a new product listing."""
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
    await db.refresh(new_product)
    return new_product


@router.get("/products", response_model=ProductListResponse)
async def get_all_products(db: AsyncSession = Depends(get_db)):
    """Get all products."""
    result = await db.execute(select(Product))
    products = result.scalars().all()
    return ProductListResponse(products=products, total=len(products))
