from typing import Annotated

from fastapi import APIRouter, Depends, Query

from .dependencies import get_music_service
from .service import MusicService

music_router = APIRouter(
    tags=["Music"]
)


@music_router.get("/search")
def search_music(
        query: Annotated[str, Query()],
        music_service: Annotated[MusicService, Depends(get_music_service)]):
    return music_service.search_youtube(query)
