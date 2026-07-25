from fastapi import APIRouter
from app.modules.auth.router import router as auth_router
# Future module imports will go here:
# from app.modules.farmers.router import router as farmer_router
# from app.modules.loans.router import router as loan_router

api_v1_router = APIRouter()

# Register all module routers here
api_v1_router.include_router(auth_router, prefix="/auth", tags=["Authentication"])
# api_v1_router.include_router(farmer_router, prefix="/farmers", tags=["Farmers"])
# api_v1_router.include_router(loan_router, prefix="/loans", tags=["Loans"])
