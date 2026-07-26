import uuid
from datetime import datetime

from sqlalchemy import JSON, DateTime, ForeignKey, Integer, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class LendingScoreHistory(Base):
    """One recalculation of a farmer's lending score (FR-13, FR-14).

    Keeping the history, the contributing factors and the human-readable reasons
    is what lets the app explain *why* a score moved instead of showing an
    unexplained number.
    """

    __tablename__ = "lending_score_history"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    farmer_user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    previous_score: Mapped[int] = mapped_column(Integer, nullable=False)
    score: Mapped[int] = mapped_column(Integer, nullable=False)

    # {"verified_harvests": 3, "repayments_made": 2, ...}
    factors: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    # ["Score increased because your previous loan was fully repaid.", ...]
    reasons: Mapped[list] = mapped_column(JSON, nullable=False, default=list)

    calculated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
