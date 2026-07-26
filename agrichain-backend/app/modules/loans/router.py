import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import get_db
from app.core.deps import get_current_user, require_roles
from app.modules.blockchain import canonical, service as ledger
from app.modules.blockchain.events import LedgerEntity, LedgerEvent
from app.modules.credit_engine import service as credit_engine
from app.modules.farmers.models import Farmer, User, UserRole
from app.modules.loans.models import Loan, LoanProduct, LoanStatus, Repayment
from app.modules.loans.schemas import (
    LoanApplyRequest,
    LoanDecisionRequest,
    LoanListResponse,
    LoanProductCreateRequest,
    LoanProductListResponse,
    LoanProductResponse,
    LoanResponse,
    RepaymentCreateRequest,
    RepaymentResponse,
    RepaymentResultResponse,
)

router = APIRouter()


async def _load_loan(db: AsyncSession, loan_id: uuid.UUID) -> Optional[Loan]:
    """Load a loan with its product eager-loaded.

    LoanResponse exposes due_date and repayment_period_months, which read
    loan.product. Serialising a lazily-loaded relationship raises
    MissingGreenlet under asyncio, so every loan returned to a client must come
    through here.
    """
    result = await db.execute(
        select(Loan).options(selectinload(Loan.product)).where(Loan.id == loan_id)
    )
    return result.scalars().first()


# --------------------------------------------------------------------------
# Loan products (FR-15)
# --------------------------------------------------------------------------


@router.post(
    "/loan-products",
    response_model=LoanProductResponse,
    status_code=status.HTTP_201_CREATED,
)
async def publish_loan_product(
    payload: LoanProductCreateRequest,
    current_user: User = Depends(require_roles(UserRole.FINANCIAL_INSTITUTION)),
    db: AsyncSession = Depends(get_db),
):
    """A financial institution publishes a loan offer.

    Not anchored: an offer is a marketing artefact that can be edited or
    withdrawn, so tamper-evidence would get in the way. The loan *agreement* is
    what gets anchored.
    """
    product = LoanProduct(
        institution_user_id=current_user.id,
        name=payload.name,
        loan_type=payload.loan_type,
        max_amount=payload.max_amount,
        interest_rate=payload.interest_rate,
        repayment_period_months=payload.repayment_period_months,
        min_lending_score=payload.min_lending_score,
        description=payload.description,
    )
    db.add(product)
    await db.commit()
    await db.refresh(product)
    return product


@router.get("/loan-products", response_model=LoanProductListResponse)
async def list_loan_products(db: AsyncSession = Depends(get_db)):
    """The loan marketplace farmers browse and compare."""
    result = await db.execute(
        select(LoanProduct)
        .where(LoanProduct.is_active.is_(True))
        .order_by(LoanProduct.interest_rate.asc())
    )
    products = list(result.scalars().all())
    return LoanProductListResponse(loan_products=products, total=len(products))


# --------------------------------------------------------------------------
# Applications and decisions (FR-16, FR-18)
# --------------------------------------------------------------------------


@router.post(
    "/loans/apply", response_model=LoanResponse, status_code=status.HTTP_201_CREATED
)
async def apply_for_loan(
    payload: LoanApplyRequest,
    current_user: User = Depends(require_roles(UserRole.FARMER)),
    db: AsyncSession = Depends(get_db),
):
    """FR-16: a farmer applies against a published loan product."""
    product = (
        await db.execute(
            select(LoanProduct).where(LoanProduct.id == payload.loan_product_id)
        )
    ).scalars().first()
    if product is None or not product.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="That loan product is not available.",
        )
    if payload.amount_requested > product.max_amount:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"The maximum for this product is {product.max_amount}. "
                f"Request a smaller amount."
            ),
        )

    profile = (
        await db.execute(select(Farmer).where(Farmer.user_id == current_user.id))
    ).scalars().first()
    score = profile.lending_score if profile else 300

    if score < product.min_lending_score:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"This product requires a lending score of at least "
                f"{product.min_lending_score}. Yours is {score}. Record and "
                f"verify harvests to improve it."
            ),
        )

    loan = Loan(
        farmer_user_id=current_user.id,
        institution_user_id=product.institution_user_id,
        loan_product_id=product.id,
        amount_requested=payload.amount_requested,
        interest_rate=product.interest_rate,
        status=LoanStatus.PENDING,
        lending_score_at_application=score,
    )
    db.add(loan)
    await db.commit()
    return await _load_loan(db, loan.id)


@router.get("/loans/mine", response_model=LoanListResponse)
async def list_my_loans(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Loan)
        .options(selectinload(Loan.product))
        .where(Loan.farmer_user_id == current_user.id)
        .order_by(Loan.applied_at.desc())
    )
    loans = list(result.scalars().all())
    return LoanListResponse(loans=loans, total=len(loans))


@router.get("/loans/applications", response_model=LoanListResponse)
async def list_applications(
    current_user: User = Depends(require_roles(UserRole.FINANCIAL_INSTITUTION)),
    db: AsyncSession = Depends(get_db),
):
    """Applications submitted against this institution's products (FR-17)."""
    result = await db.execute(
        select(Loan)
        .options(selectinload(Loan.product))
        .where(Loan.institution_user_id == current_user.id)
        .order_by(Loan.applied_at.desc())
    )
    loans = list(result.scalars().all())
    return LoanListResponse(loans=loans, total=len(loans))


@router.post("/loans/{loan_id}/decision", response_model=LoanResponse)
async def decide_loan(
    loan_id: uuid.UUID,
    payload: LoanDecisionRequest,
    current_user: User = Depends(require_roles(UserRole.FINANCIAL_INSTITUTION)),
    db: AsyncSession = Depends(get_db),
):
    """FR-18: approve or reject. Approval anchors the loan agreement."""
    loan = (
        await db.execute(select(Loan).where(Loan.id == loan_id))
    ).scalars().first()
    if loan is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Loan not found."
        )
    if loan.institution_user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This application was not submitted to your institution.",
        )
    if loan.status != LoanStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"This application is already {loan.status.value.lower()}.",
        )

    loan.decision_note = payload.note
    loan.decided_at = datetime.now()

    if not payload.approve:
        loan.status = LoanStatus.REJECTED
        # A decline is part of the credit picture, so the score is refreshed.
        await credit_engine.recompute_score(db, loan.farmer_user_id)
        await db.commit()
        return await _load_loan(db, loan.id)

    approved = payload.amount_approved or loan.amount_requested
    if approved > loan.amount_requested:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The approved amount cannot exceed the amount requested.",
        )

    loan.status = LoanStatus.ACTIVE
    loan.amount_approved = approved
    # Simple interest over the product's term, which is enough for the MVP.
    loan.total_payable = (
        approved + approved * loan.interest_rate / Decimal("100")
    ).quantize(Decimal("0.01"))
    await db.flush()

    await ledger.append_event(
        db,
        event_type=LedgerEvent.LOAN_AGREEMENT,
        entity_type=LedgerEntity.LOAN,
        entity_id=loan.id,
        payload=canonical.loan_agreement_payload(loan),
        summary={
            "amount_approved": str(loan.amount_approved),
            "interest_rate": str(loan.interest_rate),
            "total_payable": str(loan.total_payable),
            "lending_score_at_application": loan.lending_score_at_application,
        },
    )

    await db.commit()
    return await _load_loan(db, loan.id)


# --------------------------------------------------------------------------
# Repayments (FR-20)
# --------------------------------------------------------------------------


@router.post(
    "/loans/{loan_id}/repayments",
    response_model=RepaymentResultResponse,
    status_code=status.HTTP_201_CREATED,
)
async def record_repayment(
    loan_id: uuid.UUID,
    payload: RepaymentCreateRequest,
    current_user: User = Depends(require_roles(UserRole.FARMER)),
    db: AsyncSession = Depends(get_db),
):
    """Record a repayment, anchor it, and refresh the lending score.

    This is the step that closes the loop in the value proposition: repaying
    improves the score, which unlocks better credit next season.
    """
    loan = (
        await db.execute(select(Loan).where(Loan.id == loan_id))
    ).scalars().first()
    if loan is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Loan not found."
        )
    if loan.farmer_user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="This is not your loan."
        )
    if loan.status != LoanStatus.ACTIVE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Only active loans accept repayments; this one is "
            f"{loan.status.value.lower()}.",
        )
    if payload.amount > loan.outstanding_balance:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"That is more than the outstanding balance of "
                f"{loan.outstanding_balance}."
            ),
        )

    repayment = Repayment(
        loan_id=loan.id,
        amount=payload.amount,
        method=payload.method,
        transaction_reference=payload.transaction_reference,
    )
    db.add(repayment)

    loan.amount_repaid = loan.amount_repaid + payload.amount
    if loan.outstanding_balance <= 0:
        loan.status = LoanStatus.REPAID

    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        # NFR-10: a retried payment must not be recorded twice.
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                f"A repayment with reference "
                f"{payload.transaction_reference} was already recorded."
            ),
        )

    block = await ledger.append_event(
        db,
        event_type=LedgerEvent.REPAYMENT_RECORDED,
        entity_type=LedgerEntity.REPAYMENT,
        entity_id=repayment.id,
        payload=canonical.repayment_payload(repayment),
        summary={
            "amount": str(repayment.amount),
            "method": repayment.method,
            "loan_status_after": loan.status.value,
            "outstanding_balance": str(loan.outstanding_balance),
        },
    )

    score = await credit_engine.recompute_score(db, loan.farmer_user_id)

    await db.commit()
    await db.refresh(repayment)

    return RepaymentResultResponse(
        repayment=RepaymentResponse.model_validate(repayment),
        loan=LoanResponse.model_validate(await _load_loan(db, loan.id)),
        lending_score=score.score,
        score_reasons=score.reasons,
        block_index=block.index,
        block_hash=block.block_hash,
    )
