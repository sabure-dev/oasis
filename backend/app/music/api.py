from typing import Annotated
from fastapi import APIRouter, Depends, Query, Path, HTTPException

from music.service import MusicService
from music.dependencies import get_music_service

router = APIRouter(prefix="/music", tags=["Music"])


@router.get("/search")
async def search_tracks(
    query: Annotated[str, Query(min_length=1)],
    offset: Annotated[int, Query(ge=0)] = 0,
    service: Annotated[MusicService, Depends(get_music_service)] = None,
):
    try:
        return await service.search_tracks(query=query, offset=offset)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/stream/{track_id}")
async def stream_track(
    track_id: Annotated[int, Path(gt=0)],
    service: Annotated[MusicService, Depends(get_music_service)] = None,
):
    try:
        return await service.stream_track(track_id=track_id)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
