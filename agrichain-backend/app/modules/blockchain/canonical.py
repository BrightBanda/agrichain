"""Canonical payload builders — the single source of truth for what gets hashed.

The same function must build the payload when an event is anchored and when the
record is re-verified later. If the two ever diverged, an untouched record would
look tampered with. That is why anchoring never hand-rolls a dict: it calls the
builder here.

A builder must only include fields that are **immutable after the event**.
A harvest's crop and quantity belong in HARVEST_RECORDED; its verification
status does not, because that legitimately changes later and gets its own
HARVEST_VERIFIED block.
"""

import uuid
from typing import Any, Callable, Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.activities.models import Harvest
from app.modules.blockchain.events import LedgerEntity, LedgerEvent
from app.modules.blockchain.models import LedgerBlock
from app.modules.farmers.models import Farmer
from app.modules.loans.models import Loan, Repayment
from app.modules.products.models import Product

# --------------------------------------------------------------------------
# Builders: ORM row -> canonical payload
# --------------------------------------------------------------------------


def farmer_payload(farmer: Farmer) -> dict:
    return {
        "farmer_id": farmer.id,
        "user_id": farmer.user_id,
        "full_name": farmer.full_name,
        "national_id_number": farmer.national_id_number,
        "gender": farmer.gender,
        "district": farmer.district,
        "traditional_authority": farmer.traditional_authority,
        "village": farmer.village,
    }


def product_payload(product: Product) -> dict:
    return {
        "product_id": product.id,
        "user_id": product.user_id,
        "product_type": product.product_type,
        "product_name": product.product_name,
        "unit_type": product.unit_type,
        "district": product.district,
        "price_per_unit": product.price_per_unit,
        "quantity_available": product.quantity_available,
    }


def harvest_payload(harvest: Harvest) -> dict:
    return {
        "harvest_id": harvest.id,
        "user_id": harvest.user_id,
        "crop_name": harvest.crop_name,
        "quantity": harvest.quantity,
        "unit_type": harvest.unit_type,
        "harvest_date": harvest.harvest_date,
        "season": harvest.season,
        "district": harvest.district,
    }


def harvest_verification_payload(harvest: Harvest) -> dict:
    return {
        "harvest_id": harvest.id,
        "status": harvest.status,
        "verified_by_user_id": harvest.verified_by_user_id,
        "verified_at": harvest.verified_at,
    }


def loan_agreement_payload(loan: Loan) -> dict:
    # amount_repaid and status change over the life of the loan, so the
    # agreement commits only to the terms that were agreed.
    return {
        "loan_id": loan.id,
        "farmer_user_id": loan.farmer_user_id,
        "institution_user_id": loan.institution_user_id,
        "loan_product_id": loan.loan_product_id,
        "amount_approved": loan.amount_approved,
        "interest_rate": loan.interest_rate,
        "total_payable": loan.total_payable,
        "lending_score_at_application": loan.lending_score_at_application,
        "decided_at": loan.decided_at,
    }


def repayment_payload(repayment: Repayment) -> dict:
    return {
        "repayment_id": repayment.id,
        "loan_id": repayment.loan_id,
        "amount": repayment.amount,
        "method": repayment.method,
        "transaction_reference": repayment.transaction_reference,
        "paid_at": repayment.paid_at,
    }


# --------------------------------------------------------------------------
# Re-verification: entity -> (loader, builder, anchoring event)
# --------------------------------------------------------------------------


async def _load_farmer(db: AsyncSession, entity_id: uuid.UUID):
    return (
        await db.execute(select(Farmer).where(Farmer.id == entity_id))
    ).scalars().first()


async def _load_product(db: AsyncSession, entity_id: uuid.UUID):
    return (
        await db.execute(select(Product).where(Product.id == entity_id))
    ).scalars().first()


async def _load_harvest(db: AsyncSession, entity_id: uuid.UUID):
    return (
        await db.execute(select(Harvest).where(Harvest.id == entity_id))
    ).scalars().first()


async def _load_loan(db: AsyncSession, entity_id: uuid.UUID):
    return (
        await db.execute(select(Loan).where(Loan.id == entity_id))
    ).scalars().first()


async def _load_repayment(db: AsyncSession, entity_id: uuid.UUID):
    return (
        await db.execute(select(Repayment).where(Repayment.id == entity_id))
    ).scalars().first()


# entity -> (loader, payload builder, the event whose block attests to it)
VERIFIABLE: dict[
    LedgerEntity, tuple[Callable[..., Any], Callable[[Any], dict], LedgerEvent]
] = {
    LedgerEntity.FARMER: (_load_farmer, farmer_payload, LedgerEvent.FARMER_REGISTERED),
    LedgerEntity.PRODUCT: (_load_product, product_payload, LedgerEvent.PRODUCE_LISTED),
    LedgerEntity.HARVEST: (_load_harvest, harvest_payload, LedgerEvent.HARVEST_RECORDED),
    LedgerEntity.LOAN: (_load_loan, loan_agreement_payload, LedgerEvent.LOAN_AGREEMENT),
    LedgerEntity.REPAYMENT: (
        _load_repayment,
        repayment_payload,
        LedgerEvent.REPAYMENT_RECORDED,
    ),
}


async def find_block(
    db: AsyncSession,
    entity_type: LedgerEntity,
    entity_id: uuid.UUID,
    event_type: LedgerEvent,
) -> Optional[LedgerBlock]:
    result = await db.execute(
        select(LedgerBlock)
        .where(
            LedgerBlock.entity_type == entity_type,
            LedgerBlock.entity_id == entity_id,
            LedgerBlock.event_type == event_type,
        )
        .order_by(LedgerBlock.index.asc())
        .limit(1)
    )
    return result.scalars().first()
