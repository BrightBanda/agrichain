import decimal
import enum
import uuid
from datetime import date, datetime
from typing import Optional

from sqlalchemy import (
    Date,
    DateTime,
    Enum as SQLEnum,
    ForeignKey,
    Numeric,
    String,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.modules.farmers.models import User
from app.modules.products.models import UnitType


class VerificationStatus(str, enum.Enum):
    PENDING = "PENDING"
    VERIFIED = "VERIFIED"
    REJECTED = "REJECTED"


class Harvest(Base):
    """A recorded harvest (FR-07).

    Harvest history is the strongest agricultural signal the credit engine has,
    which is why a verified harvest is anchored to the ledger (FR-08, FR-23).
    """

    __tablename__ = "harvests"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    crop_name: Mapped[str] = mapped_column(String(255), nullable=False)
    quantity: Mapped[decimal.Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    unit_type: Mapped[UnitType] = mapped_column(SQLEnum(UnitType), nullable=False)
    harvest_date: Mapped[date] = mapped_column(Date, nullable=False)
    season: Mapped[str] = mapped_column(String(50), nullable=False)
    district: Mapped[str] = mapped_column(String(100), nullable=False)

    status: Mapped[VerificationStatus] = mapped_column(
        SQLEnum(VerificationStatus),
        nullable=False,
        default=VerificationStatus.PENDING,
    )
    verified_by_user_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    verified_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    farmer: Mapped["User"] = relationship("User", foreign_keys=[user_id])
