import calendar
import decimal
import enum
import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum as SQLEnum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class LoanType(str, enum.Enum):
    AGRICULTURAL = "AGRICULTURAL"
    MICROLOAN = "MICROLOAN"
    INPUT_FINANCING = "INPUT_FINANCING"
    EQUIPMENT_FINANCING = "EQUIPMENT_FINANCING"
    SEASONAL = "SEASONAL"


class LoanStatus(str, enum.Enum):
    """The application and loan lifecycle in one field.

    The specification models LoanApplication and Loan separately. This MVP keeps
    a single row and moves it through the lifecycle, which is enough to
    demonstrate the arc; splitting them is a later refactor.
    """

    PENDING = "PENDING"
    REJECTED = "REJECTED"
    ACTIVE = "ACTIVE"
    REPAID = "REPAID"


class LoanProduct(Base):
    """A loan offer published by a financial institution (FR-15)."""

    __tablename__ = "loan_products"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    institution_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    loan_type: Mapped[LoanType] = mapped_column(SQLEnum(LoanType), nullable=False)
    max_amount: Mapped[decimal.Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    interest_rate: Mapped[decimal.Decimal] = mapped_column(
        Numeric(5, 2), nullable=False
    )
    repayment_period_months: Mapped[int] = mapped_column(Integer, nullable=False)
    # Eligibility (FR-15): the minimum lending score this product will consider.
    min_lending_score: Mapped[int] = mapped_column(Integer, nullable=False, default=300)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )


class Loan(Base):
    """A farmer's loan application and, once approved, the loan itself."""

    __tablename__ = "loans"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    farmer_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    institution_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    loan_product_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("loan_products.id", ondelete="CASCADE"), nullable=False
    )

    amount_requested: Mapped[decimal.Decimal] = mapped_column(
        Numeric(14, 2), nullable=False
    )
    amount_approved: Mapped[Optional[decimal.Decimal]] = mapped_column(
        Numeric(14, 2), nullable=True
    )
    interest_rate: Mapped[decimal.Decimal] = mapped_column(
        Numeric(5, 2), nullable=False
    )
    total_payable: Mapped[Optional[decimal.Decimal]] = mapped_column(
        Numeric(14, 2), nullable=True
    )
    amount_repaid: Mapped[decimal.Decimal] = mapped_column(
        Numeric(14, 2), nullable=False, default=0
    )

    status: Mapped[LoanStatus] = mapped_column(
        SQLEnum(LoanStatus), nullable=False, default=LoanStatus.PENDING
    )
    # The lending score at the moment of application, kept for the audit trail.
    lending_score_at_application: Mapped[int] = mapped_column(
        Integer, nullable=False, default=300
    )
    decision_note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    applied_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    decided_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    product: Mapped["LoanProduct"] = relationship("LoanProduct")

    @property
    def outstanding_balance(self) -> decimal.Decimal:
        if self.total_payable is None:
            return decimal.Decimal("0")
        return self.total_payable - self.amount_repaid

    @property
    def repayment_period_months(self) -> Optional[int]:
        # Requires the product to be eager-loaded; a lazy load here would raise
        # MissingGreenlet during response serialisation.
        return self.product.repayment_period_months if self.product else None

    @property
    def due_date(self) -> Optional[datetime]:
        """When the loan falls due: the decision date plus the product's term."""
        if self.decided_at is None or self.repayment_period_months is None:
            return None
        return _add_months(self.decided_at, self.repayment_period_months)


def _add_months(moment: datetime, months: int) -> datetime:
    """Calendar-aware month arithmetic without pulling in dateutil."""
    zero_based = moment.month - 1 + months
    year = moment.year + zero_based // 12
    month = zero_based % 12 + 1
    day = min(moment.day, calendar.monthrange(year, month)[1])
    return moment.replace(year=year, month=month, day=day)


class Repayment(Base):
    """A repayment against a loan (FR-20)."""

    __tablename__ = "repayments"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    loan_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("loans.id", ondelete="CASCADE"), nullable=False, index=True
    )
    amount: Mapped[decimal.Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    method: Mapped[str] = mapped_column(String(50), nullable=False, default="MOBILE_MONEY")
    # Unique so a retried payment cannot be recorded twice (NFR-10).
    transaction_reference: Mapped[str] = mapped_column(
        String(100), nullable=False, unique=True, index=True
    )
    paid_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
