import uuid
from datetime import datetime
from typing import Optional
from decimal import Decimal
from pydantic import BaseModel, Field
from app.modules.products.models import ProductType, UnitType


class ProductCreateRequest(BaseModel):
    product_type: ProductType = Field(..., example=ProductType.CROPS_PRODUCE)
    product_name: str = Field(..., example="Dry White Hybrid Maize")
    unit_type: UnitType = Field(..., example=UnitType.BAG_50KG)
    district: str = Field(..., example="Lilongwe")
    price_per_unit: Decimal = Field(..., example=45000)
    quantity_available: int = Field(..., example=25)
    description: Optional[str] = Field(
        None, example="High quality verified farm product direct from farm."
    )


class ProductResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    product_type: ProductType
    product_name: str
    unit_type: UnitType
    district: str
    price_per_unit: Decimal
    quantity_available: int
    description: Optional[str]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
