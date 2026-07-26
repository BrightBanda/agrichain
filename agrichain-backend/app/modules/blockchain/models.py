import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import (
    JSON,
    DateTime,
    Enum as SQLEnum,
    Integer,
    String,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.modules.blockchain.events import LedgerEntity, LedgerEvent

# A hash that is all zeroes marks the start of the chain.
GENESIS_PREVIOUS_HASH = "0" * 64


class LedgerBlock(Base):
    """One block in the simulated AgriChain ledger.

    This is a *simulation*: a single-node, append-only hash chain in Postgres.
    There is no peer-to-peer network and no consensus among independent miners.
    What it does reproduce faithfully is the property that matters for the
    demo — every block commits to the one before it, so altering any historical
    record invalidates every block after it and is detectable.

    Per FR-23 and NFR-02, no personal data is stored here. A block holds the
    SHA-256 hash of the canonical event payload plus non-sensitive metadata.
    """

    __tablename__ = "ledger_blocks"

    # The block height doubles as the primary key: 0 is genesis.
    index: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )

    event_type: Mapped[LedgerEvent] = mapped_column(
        SQLEnum(LedgerEvent), nullable=False
    )
    entity_type: Mapped[LedgerEntity] = mapped_column(
        SQLEnum(LedgerEntity), nullable=False, default=LedgerEntity.NONE
    )
    # The relational row this block attests to, so it can be re-hashed later.
    entity_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), nullable=True, index=True
    )

    # SHA-256 of the canonical payload. The payload itself is never stored.
    payload_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    # Non-sensitive, human-readable context for the explorer.
    payload_summary: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)

    previous_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    nonce: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    difficulty: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    block_hash: Mapped[str] = mapped_column(
        String(64), nullable=False, unique=True, index=True
    )
