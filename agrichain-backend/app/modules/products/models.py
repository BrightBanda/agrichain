import enum
import uuid
import decimal
from datetime import datetime
from typing import Optional
from sqlalchemy import (
    String,
    ForeignKey,
    Enum as SQLEnum,
    Numeric,
    Integer,
    Text,
    DateTime,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base
from app.modules.farmers.models import User


class ProductType(str, enum.Enum):
    CROPS_PRODUCE = "CROPS_PRODUCE"
    LIVESTOCK_ANIMALS = "LIVESTOCK_ANIMALS"


class UnitType(str, enum.Enum):
    BAG_50KG = "BAG_50KG"
    BAG_25KG = "BAG_25KG"
    BAG_10KG = "BAG_10KG"
    KILOGRAM = "KILOGRAM"
    PIECE = "PIECE"
    LITER = "LITER"
    BUNCH = "BUNCH"
    CRATE = "CRATE"


class Product(Base):
    __tablename__ = "products"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Product Details
    product_type: Mapped[ProductType] = mapped_column(
        SQLEnum(ProductType), nullable=False
    )
    product_name: Mapped[str] = mapped_column(String(255), nullable=False)
    unit_type: Mapped[UnitType] = mapped_column(SQLEnum(UnitType), nullable=False)
    district: Mapped[str] = mapped_column(String(100), nullable=False)
    price_per_unit: Mapped[decimal.Decimal] = mapped_column(
        Numeric(10, 2), nullable=False
    )
    quantity_available: Mapped[int] = mapped_column(Integer, nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Timestamps
    # func.now() renders DEFAULT now(), evaluated per row. A plain "now()"
    # string would be emitted as a quoted literal and frozen at DDL time.
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )

    # Relationships
    user: Mapped["User"] = relationship("User", backref="products")
