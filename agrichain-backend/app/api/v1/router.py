from fastapi import APIRouter

from app.modules.activities.router import router as harvests_router
from app.modules.auth.router import router as auth_router
from app.modules.blockchain.router import router as blockchain_router
from app.modules.credit_engine.router import router as credit_router
from app.modules.loans.router import router as loans_router
from app.modules.products.router import router as products_router

api_v1_router = APIRouter()

# Register all module routers here
api_v1_router.include_router(auth_router, prefix="/auth", tags=["Authentication"])
api_v1_router.include_router(products_router, prefix="", tags=["Products"])
api_v1_router.include_router(harvests_router, prefix="", tags=["Harvests"])
api_v1_router.include_router(loans_router, prefix="", tags=["Lending"])
api_v1_router.include_router(credit_router, prefix="", tags=["Credit Engine"])
api_v1_router.include_router(
    blockchain_router, prefix="/blockchain", tags=["Blockchain Ledger"]
)
