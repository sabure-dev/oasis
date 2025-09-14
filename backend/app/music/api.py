from typing import Annotated

from fastapi import APIRouter, Depends, Query, Path

from .dependencies import get_dab_service
from .service import MusicService

music_router = APIRouter(
    tags=["Music"]
)


@music_router.get("/search")
async def search_tracks(
        query: Annotated[str, Query()],
        music_service: Annotated[MusicService, Depends(get_dab_service)],
        offset: Annotated[int, Query()] = 0,
):
    return await music_service.search_tracks(query=query, offset=offset)


@music_router.get("/stream/{track_id}")
async def stream_track(
        track_id: Annotated[int, Path()],
        music_service: Annotated[MusicService, Depends(get_dab_service)],
):
    return await music_service.stream_track(track_id=track_id)
