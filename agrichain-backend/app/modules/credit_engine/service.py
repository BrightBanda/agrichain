"""The lending score engine (FR-13, FR-14).

The score is deliberately transparent rather than clever. Every component is a
count of something the farmer actually did, each contribution is capped, and
each one produces a sentence explaining itself. A farmer should be able to read
the reasons and know exactly what to do to improve.
"""

import uuid
from dataclasses import dataclass, field

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.activities.models import Harvest, VerificationStatus
from app.modules.blockchain import service as ledger
from app.modules.blockchain.events import LedgerEntity, LedgerEvent
from app.modules.credit_engine.models import LendingScoreHistory
from app.modules.farmers.models import Farmer
from app.modules.loans.models import Loan, LoanStatus, Repayment
from app.modules.products.models import Product

BASE_SCORE = 300
MIN_SCORE = 300
MAX_SCORE = 850

# points per occurrence, maximum contribution
VERIFIED_HARVEST = (20, 120)
PRODUCE_LISTING = (5, 40)
REPAYMENT_MADE = (25, 150)
LOAN_FULLY_REPAID = (40, 120)
# Penalty for an application the institution turned down.
REJECTED_LOAN = (-15, -60)


@dataclass
class ScoreResult:
    score: int
    previous_score: int
    factors: dict = field(default_factory=dict)
    reasons: list[str] = field(default_factory=list)

    @property
    def delta(self) -> int:
        return self.score - self.previous_score


def _contribution(count: int, points: int, cap: int) -> int:
    """Apply per-occurrence points, bounded by the cap (works either sign)."""
    raw = count * points
    return max(raw, cap) if points < 0 else min(raw, cap)


async def recompute_score(
    db: AsyncSession, farmer_user_id: uuid.UUID, *, anchor: bool = True
) -> ScoreResult:
    """Recalculate, persist and (optionally) anchor a farmer's lending score.

    Does not commit — it joins the caller's transaction so the score, its
    history row and its ledger block land together with whatever event triggered
    the recalculation.
    """
    profile = (
        await db.execute(select(Farmer).where(Farmer.user_id == farmer_user_id))
    ).scalars().first()

    previous_score = profile.lending_score if profile else BASE_SCORE

    verified_harvests = await _count(
        db,
        select(func.count())
        .select_from(Harvest)
        .where(
            Harvest.user_id == farmer_user_id,
            Harvest.status == VerificationStatus.VERIFIED,
        ),
    )
    listings = await _count(
        db,
        select(func.count()).select_from(Product).where(Product.user_id == farmer_user_id),
    )
    repayments = await _count(
        db,
        select(func.count())
        .select_from(Repayment)
        .join(Loan, Loan.id == Repayment.loan_id)
        .where(Loan.farmer_user_id == farmer_user_id),
    )
    loans_repaid = await _count(
        db,
        select(func.count())
        .select_from(Loan)
        .where(
            Loan.farmer_user_id == farmer_user_id,
            Loan.status == LoanStatus.REPAID,
        ),
    )
    loans_rejected = await _count(
        db,
        select(func.count())
        .select_from(Loan)
        .where(
            Loan.farmer_user_id == farmer_user_id,
            Loan.status == LoanStatus.REJECTED,
        ),
    )

    parts = {
        "verified_harvests": _contribution(verified_harvests, *VERIFIED_HARVEST),
        "produce_listings": _contribution(listings, *PRODUCE_LISTING),
        "repayments_made": _contribution(repayments, *REPAYMENT_MADE),
        "loans_fully_repaid": _contribution(loans_repaid, *LOAN_FULLY_REPAID),
        "loans_rejected": _contribution(loans_rejected, *REJECTED_LOAN),
    }

    score = max(MIN_SCORE, min(MAX_SCORE, BASE_SCORE + sum(parts.values())))

    factors = {
        "base_score": BASE_SCORE,
        "verified_harvests": verified_harvests,
        "produce_listings": listings,
        "repayments_made": repayments,
        "loans_fully_repaid": loans_repaid,
        "loans_rejected": loans_rejected,
        "points": parts,
    }

    reasons = _explain(previous_score, score, factors, parts)
    result = ScoreResult(
        score=score, previous_score=previous_score, factors=factors, reasons=reasons
    )

    if profile is not None:
        profile.lending_score = score

    db.add(
        LendingScoreHistory(
            farmer_user_id=farmer_user_id,
            previous_score=previous_score,
            score=score,
            factors=factors,
            reasons=reasons,
        )
    )

    if anchor and score != previous_score:
        await ledger.append_event(
            db,
            event_type=LedgerEvent.SCORE_UPDATED,
            entity_type=LedgerEntity.LENDING_SCORE,
            entity_id=farmer_user_id,
            payload={
                "farmer_user_id": farmer_user_id,
                "previous_score": previous_score,
                "score": score,
                "factors": factors,
            },
            summary={
                "previous_score": previous_score,
                "score": score,
                "change": score - previous_score,
            },
        )

    await db.flush()
    return result


async def _count(db: AsyncSession, statement) -> int:
    return await db.scalar(statement) or 0


def _explain(
    previous_score: int, score: int, factors: dict, parts: dict
) -> list[str]:
    """Turn the arithmetic into sentences a farmer can act on (FR-14)."""
    reasons: list[str] = []

    if score > previous_score:
        reasons.append(
            f"Your score increased by {score - previous_score} points."
        )
    elif score < previous_score:
        reasons.append(
            f"Your score decreased by {previous_score - score} points."
        )
    else:
        reasons.append("Your score is unchanged.")

    if factors["loans_fully_repaid"]:
        reasons.append(
            f"You have fully repaid {factors['loans_fully_repaid']} loan(s), "
            f"which is the strongest signal lenders look for "
            f"(+{parts['loans_fully_repaid']} points)."
        )
    if factors["repayments_made"]:
        reasons.append(
            f"You have made {factors['repayments_made']} repayment(s) on time "
            f"(+{parts['repayments_made']} points)."
        )
    if factors["verified_harvests"]:
        reasons.append(
            f"{factors['verified_harvests']} of your harvests have been "
            f"independently verified (+{parts['verified_harvests']} points)."
        )
    if factors["produce_listings"]:
        reasons.append(
            f"You have listed produce {factors['produce_listings']} time(s), "
            f"showing consistent market activity "
            f"(+{parts['produce_listings']} points)."
        )
    if factors["loans_rejected"]:
        reasons.append(
            f"{factors['loans_rejected']} loan application(s) were declined "
            f"({parts['loans_rejected']} points)."
        )

    if not factors["verified_harvests"]:
        reasons.append(
            "Record a harvest and have it verified by your cooperative to "
            "raise your score."
        )

    return reasons
