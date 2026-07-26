import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user, require_roles
from app.modules.activities.models import Harvest, VerificationStatus
from app.modules.activities.schemas import (
    HarvestCreateRequest,
    HarvestListResponse,
    HarvestResponse,
    HarvestVerifyRequest,
    HarvestWithProofResponse,
)
from app.modules.blockchain import canonical, service as ledger
from app.modules.blockchain.events import LedgerEntity, LedgerEvent
from app.modules.credit_engine import service as credit_engine
from app.modules.farmers.models import User, UserRole

router = APIRouter()

# Who may attest to a harvest (FR-08).
VERIFIER_ROLES = (UserRole.COOPERATIVE, UserRole.ADMIN)


@router.post(
    "/harvests",
    response_model=HarvestWithProofResponse,
    status_code=status.HTTP_201_CREATED,
)
async def record_harvest(
    payload: HarvestCreateRequest,
    current_user: User = Depends(require_roles(UserRole.FARMER)),
    db: AsyncSession = Depends(get_db),
):
    """FR-07: record a harvest and anchor it to the ledger."""
    harvest = Harvest(
        user_id=current_user.id,
        crop_name=payload.crop_name,
        quantity=payload.quantity,
        unit_type=payload.unit_type,
        harvest_date=payload.harvest_date,
        season=payload.season,
        district=payload.district,
        status=VerificationStatus.PENDING,
    )
    db.add(harvest)
    # Populate defaults so the anchored payload matches what is stored.
    await db.flush()

    block = await ledger.append_event(
        db,
        event_type=LedgerEvent.HARVEST_RECORDED,
        entity_type=LedgerEntity.HARVEST,
        entity_id=harvest.id,
        payload=canonical.harvest_payload(harvest),
        summary={
            "crop": harvest.crop_name,
            "quantity": str(harvest.quantity),
            "unit": harvest.unit_type.value,
            "season": harvest.season,
            "district": harvest.district,
        },
    )

    # One transaction: the harvest and its block commit together or not at all.
    await db.commit()
    await db.refresh(harvest)

    return HarvestWithProofResponse(
        harvest=HarvestResponse.model_validate(harvest),
        block_index=block.index,
        block_hash=block.block_hash,
    )


@router.get("/harvests", response_model=HarvestListResponse)
async def list_my_harvests(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """The caller's own harvest history."""
    result = await db.execute(
        select(Harvest)
        .where(Harvest.user_id == current_user.id)
        .order_by(Harvest.harvest_date.desc())
    )
    harvests = list(result.scalars().all())
    return HarvestListResponse(harvests=harvests, total=len(harvests))


@router.get("/harvests/pending", response_model=HarvestListResponse)
async def list_pending_harvests(
    current_user: User = Depends(require_roles(*VERIFIER_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    """Harvests awaiting verification, for cooperatives and administrators."""
    result = await db.execute(
        select(Harvest)
        .where(Harvest.status == VerificationStatus.PENDING)
        .order_by(Harvest.created_at.asc())
    )
    harvests = list(result.scalars().all())
    return HarvestListResponse(harvests=harvests, total=len(harvests))


@router.post("/harvests/{harvest_id}/verify", response_model=HarvestWithProofResponse)
async def verify_harvest(
    harvest_id: uuid.UUID,
    payload: HarvestVerifyRequest,
    current_user: User = Depends(require_roles(*VERIFIER_ROLES)),
    db: AsyncSession = Depends(get_db),
):
    """FR-08: attest to a harvest, anchor the attestation, refresh the score."""
    harvest = (
        await db.execute(select(Harvest).where(Harvest.id == harvest_id))
    ).scalars().first()
    if harvest is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Harvest not found."
        )
    if harvest.status != VerificationStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"This harvest was already {harvest.status.value.lower()}.",
        )

    harvest.status = (
        VerificationStatus.VERIFIED if payload.approve else VerificationStatus.REJECTED
    )
    harvest.verified_by_user_id = current_user.id
    harvest.verified_at = datetime.now()
    await db.flush()

    block = await ledger.append_event(
        db,
        event_type=LedgerEvent.HARVEST_VERIFIED,
        entity_type=LedgerEntity.HARVEST,
        entity_id=harvest.id,
        payload=canonical.harvest_verification_payload(harvest),
        summary={
            "status": harvest.status.value,
            "verifier_role": current_user.role.value,
            "crop": harvest.crop_name,
        },
    )

    # A verified harvest is agricultural evidence, so the score moves (FR-13).
    if harvest.status == VerificationStatus.VERIFIED:
        await credit_engine.recompute_score(db, harvest.user_id)

    await db.commit()
    await db.refresh(harvest)

    return HarvestWithProofResponse(
        harvest=HarvestResponse.model_validate(harvest),
        block_index=block.index,
        block_hash=block.block_hash,
    )
