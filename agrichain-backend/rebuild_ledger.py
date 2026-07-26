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

    python rebuild_ledger.py --check    # report without changing anything
    python rebuild_ledger.py            # rebuild

Never expose this as an endpoint. Rewriting a chain is precisely what a real
ledger exists to prevent; it is acceptable here only because this chain is a
single-node simulation and this is a local database.
"""

import asyncio
import sys

from sqlalchemy import select

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


async def rebuild() -> None:
    async with AsyncSessionLocal() as session:
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
    asyncio.run(rebuild())
