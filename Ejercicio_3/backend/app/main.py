from fastapi import FastAPI
from app.router.v1.endpoint import router as v1_router
from app.core.config import settings

app = FastAPI(
    title=settings.app_name,
    version=settings.api_version)
app.include_router(v1_router, prefix=f"/api/v1")

@app.get("/")
async def root():
    return {"message": "Welcome to the FastAPI Application!"}
