import enum
import uuid
from datetime import datetime
from typing import Optional, List
from sqlalchemy import (
    String,
    ForeignKey,
    Enum as SQLEnum,
    Numeric,
    Integer,
    Boolean,
    DateTime,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class UserRole(str, enum.Enum):
    FARMER = "FARMER"
    FINANCIAL_INSTITUTION = "FINANCIAL_INSTITUTION"
    SUPPLIER = "SUPPLIER"
    PRODUCE_BUYER = "PRODUCE_BUYER"
    COOPERATIVE = "COOPERATIVE"
    ADMIN = "ADMIN"


class Gender(str, enum.Enum):
    MALE = "MALE"
    FEMALE = "FEMALE"
    OTHER = "OTHER"


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    phone_number: Mapped[str] = mapped_column(
        String(20), unique=True, index=True, nullable=False
    )
    email: Mapped[Optional[str]] = mapped_column(
        String(255), unique=True, nullable=True
    )
    # Organisation name for non-farmer accounts. Farmers carry their name on the
    # Farmer profile instead, so this stays null for them.
    display_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(
        SQLEnum(UserRole), nullable=False, default=UserRole.FARMER
    )
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    # func.now() renders DEFAULT now(), evaluated per row. A plain "now()"
    # string would be emitted as a quoted literal and frozen at DDL time.
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    farmer_profile: Mapped[Optional["Farmer"]] = relationship(
        "Farmer", back_populates="user", uselist=False
    )


class Farmer(Base):
    __tablename__ = "farmers"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )

    # Personal & KYC Information
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    national_id_number: Mapped[str] = mapped_column(
        String(50), unique=True, index=True, nullable=False
    )
    gender: Mapped[Gender] = mapped_column(SQLEnum(Gender), nullable=False)

    # Location Hierarchy
    district: Mapped[str] = mapped_column(String(100), nullable=False)
    traditional_authority: Mapped[str] = mapped_column(String(100), nullable=False)
    village: Mapped[str] = mapped_column(String(100), nullable=False)

    # Document / Media File URLs
    profile_photo_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    id_front_photo_url: Mapped[Optional[str]] = mapped_column(
        String(500), nullable=True
    )
    id_back_photo_url: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)

    # Credit Score
    lending_score: Mapped[int] = mapped_column(Integer, default=300)

    user: Mapped["User"] = relationship("User", back_populates="farmer_profile")
