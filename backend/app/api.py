from fastapi import APIRouter

from music.api import music_router

api_router = APIRouter()

api_router.include_router(music_router)


@api_router.get("/healthcheck")
async def healthcheck():
    return {"status": "healthy"}
