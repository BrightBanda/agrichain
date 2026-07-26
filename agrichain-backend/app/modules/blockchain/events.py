import enum


class LedgerEvent(str, enum.Enum):
    """Events that AgriChain anchors to the ledger (FR-23).

    Only events whose tamper-resistance has value are recorded. Ordinary
    application data stays in the relational tables.
    """

    GENESIS = "GENESIS"
    FARMER_REGISTERED = "FARMER_REGISTERED"
    PRODUCE_LISTED = "PRODUCE_LISTED"
    HARVEST_RECORDED = "HARVEST_RECORDED"
    HARVEST_VERIFIED = "HARVEST_VERIFIED"
    LOAN_AGREEMENT = "LOAN_AGREEMENT"
    REPAYMENT_RECORDED = "REPAYMENT_RECORDED"
    SCORE_UPDATED = "SCORE_UPDATED"


class LedgerEntity(str, enum.Enum):
    """The kind of relational record a block anchors."""

    NONE = "NONE"
    FARMER = "FARMER"
    PRODUCT = "PRODUCT"
    HARVEST = "HARVEST"
    LOAN = "LOAN"
    REPAYMENT = "REPAYMENT"
    LENDING_SCORE = "LENDING_SCORE"
