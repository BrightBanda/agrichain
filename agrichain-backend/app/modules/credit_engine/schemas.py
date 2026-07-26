import uuid
from datetime import datetime

from pydantic import BaseModel


class LendingScoreResponse(BaseModel):
    score: int
    previous_score: int
    change: int
    factors: dict
    reasons: list[str]


class ScoreHistoryEntry(BaseModel):
    id: uuid.UUID
    previous_score: int
    score: int
    factors: dict
    reasons: list[str]
    calculated_at: datetime

    class Config:
        from_attributes = True


class ScoreHistoryResponse(BaseModel):
    entries: list[ScoreHistoryEntry]
    total: int
