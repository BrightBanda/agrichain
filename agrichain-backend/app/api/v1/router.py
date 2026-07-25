from fastapi import APIRouter
from app.modules.auth.router import router as auth_router
from app.modules.products.router import router as products_router

api_v1_router = APIRouter()

# Register all module routers here
api_v1_router.include_router(auth_router, prefix="/auth", tags=["Authentication"])
api_v1_router.include_router(products_router, prefix="", tags=["Products"])
