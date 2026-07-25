from datetime import datetime

import enum
import uuid

from typing import List, Optional

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum as SQLEnum,
    ForeignKey,
    Integer,
    Numeric,
    String,
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
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(SQLEnum(UserRole), nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

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
    location: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    lending_score: Mapped[int] = mapped_column(Integer, default=300)

    user: Mapped["User"] = relationship("User", back_populates="farmer_profile")
    farms: Mapped[List["Farm"]] = relationship("Farm", back_populates="farmer")


class Farm(Base):
    __tablename__ = "farms"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    farmer_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("farmers.id", ondelete="CASCADE"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    size_in_acres: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    location: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    farmer: Mapped["Farmer"] = relationship("Farmer", back_populates="farms")
