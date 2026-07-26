"""The simulated AgriChain ledger.

What is real here: SHA-256 hashing, the block-links-to-parent structure, the
proof-of-work loop, and tamper detection. Those are genuine and the demo can be
trusted to behave like the real thing.

What is simulated: there is one node (this server) and one writer, so there is
no peer-to-peer gossip, no competing chains and no consensus. Difficulty is set
low enough to mine instantly. A production system would replace this module with
a real distributed ledger while keeping the same interface.
"""

import decimal
import hashlib
import json
import uuid
from datetime import date, datetime
from typing import Any, Optional

from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.blockchain.events import LedgerEntity, LedgerEvent
from app.modules.blockchain.models import GENESIS_PREVIOUS_HASH, LedgerBlock

# Leading hex zeroes required of a block hash. Kept tiny so mining a block is
# instant; the loop is otherwise identical to a real proof-of-work.
DIFFICULTY = 3

# Guards against two requests mining onto the same parent. A real chain resolves
# this with consensus; a single-node simulation just serialises the writers.
_APPEND_LOCK_KEY = 918_273_645


def canonical_json(payload: Any) -> str:
    """Serialise a payload so the same data always hashes to the same digest.

    Key order, whitespace and the representation of dates, UUIDs and decimals
    all have to be pinned, otherwise re-hashing a record later would produce a
    different digest and look like tampering.
    """
    return json.dumps(
        payload,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=True,
        default=_encode,
    )


def _encode(value: Any) -> str:
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    if isinstance(value, uuid.UUID):
        return str(value)
    if isinstance(value, decimal.Decimal):
        # Normalise so 45000 and 45000.00 hash identically.
        return format(value.normalize(), "f")
    if hasattr(value, "value"):  # Enum
        return str(value.value)
    raise TypeError(f"cannot canonicalise {type(value)!r}")


def sha256(data: str) -> str:
    return hashlib.sha256(data.encode("utf-8")).hexdigest()


def hash_payload(payload: dict) -> str:
    """The digest a block commits to."""
    return sha256(canonical_json(payload))


def compute_block_hash(
    *,
    index: int,
    created_at: datetime,
    event_type: LedgerEvent,
    entity_type: LedgerEntity,
    entity_id: Optional[uuid.UUID],
    payload_hash: str,
    previous_hash: str,
    nonce: int,
) -> str:
    """Hash the block header. Every field is covered, including the parent."""
    return sha256(
        canonical_json(
            {
                "index": index,
                "created_at": created_at,
                "event_type": event_type,
                "entity_type": entity_type,
                "entity_id": entity_id,
                "payload_hash": payload_hash,
                "previous_hash": previous_hash,
                "nonce": nonce,
            }
        )
    )


def mine(
    *,
    index: int,
    created_at: datetime,
    event_type: LedgerEvent,
    entity_type: LedgerEntity,
    entity_id: Optional[uuid.UUID],
    payload_hash: str,
    previous_hash: str,
    difficulty: int = DIFFICULTY,
) -> tuple[str, int]:
    """Search for a nonce whose block hash has `difficulty` leading zeroes."""
    target = "0" * difficulty
    nonce = 0
    while True:
        candidate = compute_block_hash(
            index=index,
            created_at=created_at,
            event_type=event_type,
            entity_type=entity_type,
            entity_id=entity_id,
            payload_hash=payload_hash,
            previous_hash=previous_hash,
            nonce=nonce,
        )
        if candidate.startswith(target):
            return candidate, nonce
        nonce += 1


async def _tip(db: AsyncSession) -> Optional[LedgerBlock]:
    result = await db.execute(
        select(LedgerBlock).order_by(LedgerBlock.index.desc()).limit(1)
    )
    return result.scalars().first()


async def append_event(
    db: AsyncSession,
    *,
    event_type: LedgerEvent,
    payload: dict,
    entity_type: LedgerEntity = LedgerEntity.NONE,
    entity_id: Optional[uuid.UUID] = None,
    summary: Optional[dict] = None,
) -> LedgerBlock:
    """Mine one block onto the tip of the chain.

    This deliberately does **not** commit. It joins the caller's transaction so
    the domain row and its ledger entry are written atomically: a harvest can
    never exist without its block, and a block can never attest to a harvest
    that rolled back.
    """
    # Serialise appends for the rest of this transaction.
    await db.execute(text("SELECT pg_advisory_xact_lock(:key)"), {"key": _APPEND_LOCK_KEY})

    tip = await _tip(db)
    if tip is None:
        tip = await _create_genesis(db)

    index = tip.index + 1
    created_at = datetime.now()
    payload_hash = hash_payload(payload)

    block_hash, nonce = mine(
        index=index,
        created_at=created_at,
        event_type=event_type,
        entity_type=entity_type,
        entity_id=entity_id,
        payload_hash=payload_hash,
        previous_hash=tip.block_hash,
    )

    block = LedgerBlock(
        index=index,
        created_at=created_at,
        event_type=event_type,
        entity_type=entity_type,
        entity_id=entity_id,
        payload_hash=payload_hash,
        payload_summary=summary or {},
        previous_hash=tip.block_hash,
        nonce=nonce,
        difficulty=DIFFICULTY,
        block_hash=block_hash,
    )
    db.add(block)
    await db.flush()
    return block


async def _create_genesis(db: AsyncSession) -> LedgerBlock:
    created_at = datetime.now()
    payload = {"chain": "AgriChain", "network": "simulation"}
    payload_hash = hash_payload(payload)

    block_hash, nonce = mine(
        index=0,
        created_at=created_at,
        event_type=LedgerEvent.GENESIS,
        entity_type=LedgerEntity.NONE,
        entity_id=None,
        payload_hash=payload_hash,
        previous_hash=GENESIS_PREVIOUS_HASH,
    )

    genesis = LedgerBlock(
        index=0,
        created_at=created_at,
        event_type=LedgerEvent.GENESIS,
        entity_type=LedgerEntity.NONE,
        entity_id=None,
        payload_hash=payload_hash,
        payload_summary={"note": "AgriChain simulated ledger genesis block"},
        previous_hash=GENESIS_PREVIOUS_HASH,
        nonce=nonce,
        difficulty=DIFFICULTY,
        block_hash=block_hash,
    )
    db.add(genesis)
    await db.flush()
    return genesis


async def ensure_genesis(db: AsyncSession) -> LedgerBlock:
    """Create the genesis block if the chain is empty."""
    tip = await _tip(db)
    if tip is not None:
        return tip
    genesis = await _create_genesis(db)
    await db.commit()
    return genesis


async def verify_chain(db: AsyncSession) -> dict:
    """Walk the whole chain and report any break.

    Three independent checks per block:
      1. the recorded hash still matches a re-hash of the header (no field edited)
      2. previous_hash equals the parent's hash (no block swapped or removed)
      3. the hash still satisfies the difficulty target (no re-mine shortcut)
    """
    result = await db.execute(select(LedgerBlock).order_by(LedgerBlock.index.asc()))
    blocks = list(result.scalars().all())

    problems: list[dict] = []
    expected_previous = GENESIS_PREVIOUS_HASH

    for position, block in enumerate(blocks):
        recomputed = compute_block_hash(
            index=block.index,
            created_at=block.created_at,
            event_type=block.event_type,
            entity_type=block.entity_type,
            entity_id=block.entity_id,
            payload_hash=block.payload_hash,
            previous_hash=block.previous_hash,
            nonce=block.nonce,
        )

        if recomputed != block.block_hash:
            problems.append(
                {
                    "index": block.index,
                    "issue": "HASH_MISMATCH",
                    "detail": (
                        "The block's contents no longer hash to its recorded "
                        "hash, so a field was altered after it was mined."
                    ),
                    "expected": recomputed,
                    "found": block.block_hash,
                }
            )

        if block.previous_hash != expected_previous:
            problems.append(
                {
                    "index": block.index,
                    "issue": "BROKEN_LINK",
                    "detail": (
                        "This block does not point at the previous block's "
                        "hash, so the chain was re-ordered or a block changed."
                    ),
                    "expected": expected_previous,
                    "found": block.previous_hash,
                }
            )

        if not block.block_hash.startswith("0" * block.difficulty):
            problems.append(
                {
                    "index": block.index,
                    "issue": "DIFFICULTY_NOT_MET",
                    "detail": "The block hash does not satisfy its stated difficulty.",
                    "expected": f"hash starting with {'0' * block.difficulty}",
                    "found": block.block_hash,
                }
            )

        if block.index != position:
            problems.append(
                {
                    "index": block.index,
                    "issue": "MISSING_BLOCK",
                    "detail": "Block heights are not contiguous; a block was deleted.",
                    "expected": str(position),
                    "found": str(block.index),
                }
            )

        # Chain from the *recomputed* hash, not the stored one. If this block was
        # altered, its true hash changed, so the next block's previous_hash no
        # longer matches and the break propagates forward — exactly how a real
        # chain makes history immutable.
        expected_previous = recomputed

    return {
        "valid": not problems,
        "block_count": len(blocks),
        "tip_hash": blocks[-1].block_hash if blocks else None,
        "problems": problems,
        "checked_at": datetime.now(),
    }


async def blocks_for_entity(
    db: AsyncSession, entity_type: LedgerEntity, entity_id: uuid.UUID
) -> list[LedgerBlock]:
    result = await db.execute(
        select(LedgerBlock)
        .where(
            LedgerBlock.entity_type == entity_type,
            LedgerBlock.entity_id == entity_id,
        )
        .order_by(LedgerBlock.index.asc())
    )
    return list(result.scalars().all())


async def chain_length(db: AsyncSession) -> int:
    return await db.scalar(select(func.count()).select_from(LedgerBlock)) or 0
