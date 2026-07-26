import uuid

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.deps import get_current_user
from app.modules.credit_engine import service as credit_engine
from app.modules.credit_engine.models import LendingScoreHistory
from app.modules.credit_engine.schemas import (
    LendingScoreResponse,
    ScoreHistoryEntry,
    ScoreHistoryResponse,
)
from app.modules.farmers.models import User

router = APIRouter()


@router.get("/lending-score", response_model=LendingScoreResponse)
async def get_lending_score(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """The caller's current score with the reasons behind it (FR-13, FR-14).

    Recalculated on read so the explanation always reflects current data, then
    committed because a recalculation may move the score and write history.
    """
    result = await credit_engine.recompute_score(db, current_user.id)
    await db.commit()

    return LendingScoreResponse(
        score=result.score,
        previous_score=result.previous_score,
        change=result.delta,
        factors=result.factors,
        reasons=result.reasons,
    )


@router.get("/lending-score/history", response_model=ScoreHistoryResponse)
async def get_score_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """How the score moved over time (FR-13)."""
    result = await db.execute(
        select(LendingScoreHistory)
        .where(LendingScoreHistory.farmer_user_id == current_user.id)
        .order_by(LendingScoreHistory.calculated_at.desc())
        .limit(50)
    )
    entries = [
        ScoreHistoryEntry.model_validate(entry) for entry in result.scalars().all()
    ]
    return ScoreHistoryResponse(entries=entries, total=len(entries))
