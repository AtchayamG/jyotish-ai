"""app/api/v1/router.py"""
from fastapi import APIRouter
from app.api.v1.endpoints.auth import router as auth_router
from app.api.v1.endpoints.astrology import router as astrology_router
from app.api.v1.endpoints.admin import router as admin_router
from app.api.v1.endpoints.seed import router as seed_router  # DELETE AFTER USE

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth_router)
api_router.include_router(astrology_router)
api_router.include_router(admin_router)
api_router.include_router(seed_router)  # DELETE AFTER USE
