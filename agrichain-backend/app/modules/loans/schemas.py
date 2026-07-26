import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field

from app.modules.loans.models import LoanStatus, LoanType


class LoanProductCreateRequest(BaseModel):
    name: str = Field(..., example="Seasonal Input Loan")
    loan_type: LoanType = Field(..., example=LoanType.INPUT_FINANCING)
    max_amount: Decimal = Field(..., gt=0, example=500000)
    interest_rate: Decimal = Field(..., ge=0, example=18.5)
    repayment_period_months: int = Field(..., gt=0, example=9)
    min_lending_score: int = Field(300, ge=0, example=350)
    description: Optional[str] = Field(
        None, example="Finance seed and fertilizer for the 2025/2026 season."
    )


class LoanProductResponse(BaseModel):
    id: uuid.UUID
    institution_user_id: uuid.UUID
    name: str
    loan_type: LoanType
    max_amount: Decimal
    interest_rate: Decimal
    repayment_period_months: int
    min_lending_score: int
    description: Optional[str]
    is_active: bool
    created_at: datetime

    # Denormalised so the loan marketplace needs only one call.
    institution_name: Optional[str] = None
    monthly_fee_percent: Optional[Decimal] = None

    class Config:
        from_attributes = True


class LoanProductListResponse(BaseModel):
    loan_products: list[LoanProductResponse]
    total: int


class LoanApplyRequest(BaseModel):
    loan_product_id: uuid.UUID
    amount_requested: Decimal = Field(..., gt=0, example=250000)


class LoanDecisionRequest(BaseModel):
    approve: bool = Field(..., example=True)
    # Lets the institution offer a different amount (FR-18).
    amount_approved: Optional[Decimal] = Field(None, gt=0, example=200000)
    note: Optional[str] = Field(None, example="Approved on verified harvest history.")


class LoanResponse(BaseModel):
    id: uuid.UUID
    farmer_user_id: uuid.UUID
    institution_user_id: uuid.UUID
    loan_product_id: uuid.UUID
    amount_requested: Decimal
    amount_approved: Optional[Decimal]
    interest_rate: Decimal
    total_payable: Optional[Decimal]
    amount_repaid: Decimal
    outstanding_balance: Decimal
    status: LoanStatus
    lending_score_at_application: int
    decision_note: Optional[str]
    applied_at: datetime
    decided_at: Optional[datetime]
    repayment_period_months: Optional[int] = None
    due_date: Optional[datetime] = None
    # Denormalised so a reviewing institution sees a person, not a UUID.
    farmer_name: Optional[str] = None
    farmer_phone: Optional[str] = None

    class Config:
        from_attributes = True


class LoanListResponse(BaseModel):
    loans: list[LoanResponse]
    total: int


class RepaymentCreateRequest(BaseModel):
    amount: Decimal = Field(..., gt=0, example=50000)
    method: str = Field("MOBILE_MONEY", example="MOBILE_MONEY")
    transaction_reference: str = Field(..., example="MM-2026-000123")


class RepaymentResponse(BaseModel):
    id: uuid.UUID
    loan_id: uuid.UUID
    amount: Decimal
    method: str
    transaction_reference: str
    paid_at: datetime

    class Config:
        from_attributes = True


class RepaymentResultResponse(BaseModel):
    """A repayment, the loan it updated, and the score change it caused."""

    repayment: RepaymentResponse
    loan: LoanResponse
    lending_score: int
    score_reasons: list[str]
    block_index: Optional[int]
    block_hash: Optional[str]
