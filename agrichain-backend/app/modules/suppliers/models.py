import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import JSON, DateTime, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.modules.products.models import ProductType


class SupplierProfile(Base):
    """A service provider's business details and the inputs they supply (FR-11).

    [services] holds ProductType values drawn from SUPPLY_TYPES — what this
    business is allowed to list. Stored as JSON rather than a join table because
    it is a short, read-mostly list that is always loaded with the profile.
    """

    __tablename__ = "supplier_profiles"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )

    business_name: Mapped[str] = mapped_column(String(255), nullable=False)
    district: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    description: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)

    # e.g. ["SEEDS", "FERTILIZER"]
    services: Mapped[list] = mapped_column(JSON, nullable=False, default=list)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    user: Mapped["User"] = relationship(  # noqa: F821
        "User", back_populates="supplier_profile"
    )

    @property
    def service_types(self) -> list[ProductType]:
        """The declared services as enum members, ignoring unknown values."""
        resolved = []
        for value in self.services or []:
            try:
                resolved.append(ProductType(value))
            except ValueError:
                continue
        return resolved

    def may_list(self, product_type: ProductType) -> bool:
        return product_type in self.service_types
