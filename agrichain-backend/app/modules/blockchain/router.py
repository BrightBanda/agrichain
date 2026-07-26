import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.modules.blockchain import canonical, service as ledger
from app.modules.blockchain.events import LedgerEntity, LedgerEvent
from app.modules.blockchain.models import LedgerBlock
from app.modules.blockchain.schemas import (
    BlockResponse,
    ChainIntegrityResponse,
    ChainResponse,
    ChainStatsResponse,
    RecordVerifyRequest,
    RecordVerifyResponse,
)

router = APIRouter()


@router.get("/chain", response_model=ChainResponse)
async def get_chain(
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
):
    """The ledger, newest block first. Public: the point of a ledger is that
    anyone can inspect it."""
    await ledger.ensure_genesis(db)

    total = await ledger.chain_length(db)
    result = await db.execute(
        select(LedgerBlock)
        .order_by(LedgerBlock.index.desc())
        .offset(offset)
        .limit(limit)
    )
    blocks = list(result.scalars().all())

    tip = await db.execute(
        select(LedgerBlock.block_hash).order_by(LedgerBlock.index.desc()).limit(1)
    )
    return ChainResponse(blocks=blocks, total=total, tip_hash=tip.scalars().first())


@router.get("/chain/stats", response_model=ChainStatsResponse)
async def get_chain_stats(db: AsyncSession = Depends(get_db)):
    await ledger.ensure_genesis(db)

    rows = await db.execute(
        select(LedgerBlock.event_type, func.count()).group_by(LedgerBlock.event_type)
    )
    events = {event.value: count for event, count in rows.all()}

    tip = await db.execute(
        select(LedgerBlock.block_hash).order_by(LedgerBlock.index.desc()).limit(1)
    )

    return ChainStatsResponse(
        block_count=await ledger.chain_length(db),
        tip_hash=tip.scalars().first(),
        difficulty=ledger.DIFFICULTY,
        events=events,
        note=(
            "Simulated single-node ledger. Hashing, block linkage, proof-of-work "
            "and tamper detection are real; there is no peer-to-peer network or "
            "consensus among independent nodes."
        ),
    )


@router.get("/blocks/{index}", response_model=BlockResponse)
async def get_block(index: int, db: AsyncSession = Depends(get_db)):
    block = (
        await db.execute(select(LedgerBlock).where(LedgerBlock.index == index))
    ).scalars().first()
    if block is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No block at height {index}.",
        )
    return block


@router.get("/verify", response_model=ChainIntegrityResponse)
async def verify_chain(db: AsyncSession = Depends(get_db)):
    """Re-hash every block and check every link (FR-23)."""
    await ledger.ensure_genesis(db)
    return await ledger.verify_chain(db)


@router.get(
    "/records/{entity_type}/{entity_id}",
    response_model=list[BlockResponse],
)
async def get_record_blocks(
    entity_type: LedgerEntity,
    entity_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Every block that mentions one record — its on-chain audit trail."""
    return await ledger.blocks_for_entity(db, entity_type, entity_id)


@router.post("/verify-record", response_model=RecordVerifyResponse)
async def verify_record(
    payload: RecordVerifyRequest, db: AsyncSession = Depends(get_db)
):
    """Re-hash a live database row and compare it against the ledger.

    This is the check that carries the value proposition: a lender does not have
    to trust that AgriChain's database was never edited. If a single field of the
    harvest changed since it was anchored, the hashes will not match.
    """
    entry = canonical.VERIFIABLE.get(payload.entity_type)
    if entry is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"{payload.entity_type.value} records are not anchored.",
        )

    loader, builder, event_type = entry
    block = await canonical.find_block(
        db, payload.entity_type, payload.entity_id, event_type
    )

    if block is None:
        return RecordVerifyResponse(
            entity_type=payload.entity_type,
            entity_id=payload.entity_id,
            anchored=False,
            matches=False,
            message=(
                "This record has no ledger entry, so it cannot be verified. "
                "Records created before the ledger existed are not anchored."
            ),
        )

    record = await loader(db, payload.entity_id)
    if record is None:
        return RecordVerifyResponse(
            entity_type=payload.entity_type,
            entity_id=payload.entity_id,
            anchored=True,
            matches=False,
            message=(
                "The ledger holds a block for this record but the record itself "
                "is gone from the database. It was deleted after being anchored."
            ),
            block_index=block.index,
            block_hash=block.block_hash,
            anchored_payload_hash=block.payload_hash,
        )

    current_hash = ledger.hash_payload(builder(record))
    matches = current_hash == block.payload_hash

    return RecordVerifyResponse(
        entity_type=payload.entity_type,
        entity_id=payload.entity_id,
        anchored=True,
        matches=matches,
        message=(
            f"Verified. This record is unchanged since it was anchored in block "
            f"{block.index}."
            if matches
            else (
                f"Tampering detected. This record no longer matches the hash "
                f"committed in block {block.index}, so it was modified after "
                f"being anchored."
            )
        ),
        block_index=block.index,
        block_hash=block.block_hash,
        anchored_payload_hash=block.payload_hash,
        current_payload_hash=current_hash,
    )


# --------------------------------------------------------------------------
# Demonstration endpoints
#
# These exist so the tamper detection can be shown working, and they are the one
# place in the system that deliberately corrupts data. They refuse to run unless
# DEBUG is on, and must never be exposed in production.
# --------------------------------------------------------------------------


def _require_debug() -> None:
    if not settings.DEBUG:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Demonstration endpoints are disabled outside DEBUG mode.",
        )


@router.post("/demo/tamper-block/{index}", response_model=ChainIntegrityResponse)
async def demo_tamper_block(index: int, db: AsyncSession = Depends(get_db)):
    """Edit a block's stored summary without re-mining it, then verify.

    Shows check 1: the block no longer hashes to its recorded hash, and because
    every later block commits to this one, the break cascades forward.
    """
    _require_debug()

    block = (
        await db.execute(select(LedgerBlock).where(LedgerBlock.index == index))
    ).scalars().first()
    if block is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail=f"No block at height {index}."
        )
    if block.event_type == LedgerEvent.GENESIS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Pick a block above the genesis block.",
        )

    # Change the committed payload hash, leaving block_hash stale.
    block.payload_hash = ledger.sha256(f"tampered-{block.payload_hash}")
    await db.commit()

    return await ledger.verify_chain(db)


@router.post("/demo/tamper-record", response_model=RecordVerifyResponse)
async def demo_tamper_record(
    payload: RecordVerifyRequest, db: AsyncSession = Depends(get_db)
):
    """Quietly edit a database row and show that verification catches it.

    This is the more realistic attack: the ledger is untouched and still
    perfectly valid, but the underlying record was altered, so re-hashing it no
    longer matches what was committed.
    """
    _require_debug()

    entry = canonical.VERIFIABLE.get(payload.entity_type)
    if entry is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"{payload.entity_type.value} records are not anchored.",
        )

    loader, _, _ = entry
    record = await loader(db, payload.entity_id)
    if record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Record not found."
        )

    # Inflate a quantity or amount — the kind of edit that would flatter a
    # farmer's credit profile.
    for attribute in ("quantity", "quantity_available", "amount", "amount_approved"):
        if hasattr(record, attribute) and getattr(record, attribute) is not None:
            current = getattr(record, attribute)
            setattr(record, attribute, type(current)(current) * 2)
            break
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This record has no numeric field to tamper with.",
        )

    await db.commit()
    return await verify_record(payload, db)
