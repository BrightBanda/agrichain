import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field

from app.modules.activities.models import VerificationStatus
from app.modules.products.models import UnitType


class HarvestCreateRequest(BaseModel):
    crop_name: str = Field(..., example="Dry White Hybrid Maize")
    quantity: Decimal = Field(..., gt=0, example=120)
    unit_type: UnitType = Field(..., example=UnitType.BAG_50KG)
    harvest_date: date = Field(..., example="2026-05-14")
    season: str = Field(..., example="2025/2026")
    district: str = Field(..., example="Lilongwe")


class HarvestResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    crop_name: str
    quantity: Decimal
    unit_type: UnitType
    harvest_date: date
    season: str
    district: str
    status: VerificationStatus
    verified_by_user_id: Optional[uuid.UUID]
    verified_at: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True


class HarvestListResponse(BaseModel):
    harvests: list[HarvestResponse]
    total: int


class HarvestVerifyRequest(BaseModel):
    approve: bool = Field(True, example=True)
    note: Optional[str] = Field(None, example="Confirmed against cooperative records.")


class HarvestWithProofResponse(BaseModel):
    """A harvest plus the ledger block that attests to it."""

    harvest: HarvestResponse
    block_index: Optional[int]
    block_hash: Optional[str]
