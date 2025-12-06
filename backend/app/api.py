from fastapi import APIRouter
from users.api import router as users_router
from music.api import router as music_router

api_router = APIRouter()

api_router.include_router(users_router)
api_router.include_router(music_router)


@api_router.get("/healthcheck")
async def healthcheck():
    return {"status": "healthy"}