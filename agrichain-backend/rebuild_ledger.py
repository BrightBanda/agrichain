"""Repair a ledger whose block sequence has been broken.

Development tool only. A hash chain is append-only: if blocks are deleted from
the middle, the survivors still point at hashes that no longer exist and the
chain fails verification forever. That is the ledger working correctly, but it
leaves a dev database stuck.

This re-mines every surviving block in its original chronological order,
reassigning contiguous heights and relinking each block to its new parent.
Crucially it preserves each block's `payload_hash`, so every record that was
verifiable before is still verifiable afterwards — only the chain scaffolding is
rebuilt, never the attestations themselves.

    python rebuild_ledger.py --check      # report without changing anything
    python rebuild_ledger.py              # relink and re-mine
    python rebuild_ledger.py --reanchor   # also re-derive damaged payload hashes

Two different kinds of damage need different repairs:

* **Blocks deleted from the middle.** The survivors' payload hashes are still
  correct, so a plain rebuild relinks them and everything stays verifiable.
* **A block's payload_hash overwritten** (what the tamper-block demo does). The
  commitment itself is destroyed, so relinking alone produces a chain that
  verifies while the underlying record reports "tampered" forever. `--reanchor`
  recomputes those hashes from the live records, which is only sound because this
  is a local simulation: on a real chain the commitment is exactly what you are
  not allowed to rewrite.

Never expose this as an endpoint. Rewriting a chain is precisely what a real
ledger exists to prevent; it is acceptable here only because this chain is a
single-node simulation and this is a local database.
"""

import asyncio
import sys

from sqlalchemy import select

from app import models  # noqa: F401  (completes the mapper registry)
from app.core.database import AsyncSessionLocal
from app.modules.blockchain import service as ledger
from app.modules.blockchain.events import LedgerEvent
from app.modules.blockchain.models import GENESIS_PREVIOUS_HASH, LedgerBlock


async def report() -> bool:
    """Print the current integrity verdict. Returns True when the chain is valid."""
    async with AsyncSessionLocal() as session:
        result = await ledger.verify_chain(session)

        print(f"blocks      : {result['block_count']}")
        print(f"chain valid : {result['valid']}")
        for problem in result["problems"][:10]:
            print(
                f"  block {problem['index']}: {problem['issue']}"
                f" — {problem['detail']}"
            )
        extra = len(result["problems"]) - 10
        if extra > 0:
            print(f"  ... and {extra} more")
        return bool(result["valid"])


async def reanchor(session) -> int:
    """Re-derive payload hashes that no longer match their live record.

    Only touches blocks whose record still exists and whose hash is wrong;
    everything else is left exactly as mined. Returns how many were repaired.
    """
    from app.modules.blockchain import canonical

    result = await session.execute(select(LedgerBlock).order_by(LedgerBlock.index))
    repaired = 0

    for block in result.scalars().all():
        entry = canonical.VERIFIABLE.get(block.entity_type)
        if entry is None or block.entity_id is None:
            continue
        loader, builder, event_type = entry
        if block.event_type != event_type:
            continue

        record = await loader(session, block.entity_id)
        if record is None:
            # Deleted record: nothing to re-derive from, so leave the block as
            # the historical attestation it is.
            continue

        current = ledger.hash_payload(builder(record))
        if current != block.payload_hash:
            print(
                f"  re-anchored #{block.index} {block.event_type.value}: "
                f"{block.payload_hash[:12]}… -> {current[:12]}…"
            )
            block.payload_hash = current
            repaired += 1

    return repaired


async def rebuild(*, also_reanchor: bool = False) -> None:
    async with AsyncSessionLocal() as session:
        if also_reanchor:
            print("re-deriving damaged payload hashes...")
            count = await reanchor(session)
            print(f"  {count} block(s) re-anchored\n")
            await session.flush()

        blocks = list(
            (
                await session.execute(
                    select(LedgerBlock).order_by(
                        LedgerBlock.created_at.asc(), LedgerBlock.index.asc()
                    )
                )
            )
            .scalars()
            .all()
        )

        if not blocks:
            print("the chain is empty; nothing to rebuild")
            return

        # Genesis must lead, whatever its timestamp says.
        blocks.sort(key=lambda block: (block.event_type != LedgerEvent.GENESIS,))
        ordered = [b for b in blocks if b.event_type == LedgerEvent.GENESIS]
        ordered += [b for b in blocks if b.event_type != LedgerEvent.GENESIS]

        if len(ordered) != len(blocks):  # pragma: no cover - defensive
            raise RuntimeError("block partition lost entries")

        print(f"rebuilding {len(ordered)} block(s)...")

        # Heights are the primary key, so collisions during renumbering are
        # avoided by parking every block above the current maximum first.
        offset = max(block.index for block in ordered) + 1
        for position, block in enumerate(ordered):
            block.index = offset + position
        await session.flush()

        previous_hash = GENESIS_PREVIOUS_HASH
        for height, block in enumerate(ordered):
            block.index = height
            block.previous_hash = previous_hash

            block_hash, nonce = ledger.mine(
                index=height,
                created_at=block.created_at,
                event_type=block.event_type,
                entity_type=block.entity_type,
                entity_id=block.entity_id,
                # Untouched: this is the commitment to the record itself.
                payload_hash=block.payload_hash,
                previous_hash=previous_hash,
            )
            block.block_hash = block_hash
            block.nonce = nonce
            block.difficulty = ledger.DIFFICULTY
            previous_hash = block_hash

            print(
                f"  #{height:<3} {block.event_type.value:<20} "
                f"{block_hash[:16]}…"
            )

        await session.commit()
        print("done.\n")

    await report()


if __name__ == "__main__":
    if "--check" in sys.argv:
        valid = asyncio.run(report())
        sys.exit(0 if valid else 1)
    asyncio.run(rebuild(also_reanchor="--reanchor" in sys.argv))
