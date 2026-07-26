import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.modules.blockchain.events import LedgerEntity, LedgerEvent


class BlockResponse(BaseModel):
    index: int
    created_at: datetime
    event_type: LedgerEvent
    entity_type: LedgerEntity
    entity_id: Optional[uuid.UUID]
    payload_hash: str
    payload_summary: dict
    previous_hash: str
    nonce: int
    difficulty: int
    block_hash: str

    class Config:
        from_attributes = True


class ChainResponse(BaseModel):
    blocks: list[BlockResponse]
    total: int
    tip_hash: Optional[str]


class ChainProblem(BaseModel):
    index: int
    issue: str
    detail: str
    expected: Optional[str]
    found: Optional[str]


class ChainIntegrityResponse(BaseModel):
    valid: bool
    block_count: int
    tip_hash: Optional[str]
    problems: list[ChainProblem]
    checked_at: datetime


class RecordVerifyRequest(BaseModel):
    entity_type: LedgerEntity = Field(..., example=LedgerEntity.HARVEST)
    entity_id: uuid.UUID


class RecordVerifyResponse(BaseModel):
    """Does the database row still match what the ledger committed to?"""

    entity_type: LedgerEntity
    entity_id: uuid.UUID
    anchored: bool
    matches: bool
    message: str
    block_index: Optional[int] = None
    block_hash: Optional[str] = None
    anchored_payload_hash: Optional[str] = None
    current_payload_hash: Optional[str] = None


class ChainStatsResponse(BaseModel):
    block_count: int
    tip_hash: Optional[str]
    difficulty: int
    events: dict[str, int]
    is_simulation: bool = True
    note: str
