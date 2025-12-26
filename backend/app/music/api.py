from typing import Annotated

from fastapi import APIRouter, Depends, Query, Path, status

from music.dependencies import get_music_service
from music.schemas import TrackBase, PlaylistResponse, PlaylistCreate
from music.service import MusicService

router = APIRouter(prefix="/music", tags=["Music"])


@router.get("/search")
async def search_tracks(
        query: Annotated[str, Query(min_length=1)],
        offset: Annotated[int, Query(ge=0)] = 0,
        service: Annotated[MusicService, Depends(get_music_service)] = None,
):
    return await service.search_tracks(query=query, offset=offset)


@router.get("/stream/{track_id}")
async def stream_track(
        track_id: Annotated[int, Path(gt=0)],
        service: Annotated[MusicService, Depends(get_music_service)] = None,
):
    return await service.stream_track(track_id=track_id)


@router.get("/playlists", response_model=list[PlaylistResponse])
async def get_playlists(
        service: Annotated[MusicService, Depends(get_music_service)]
):
    playlists = await service.get_playlists()
    response = []
    for p in playlists:
        tracks = [
            TrackBase(
                id=int(t.source_id),
                title=t.title,
                artist=t.artist,
                album=t.album,
                album_cover=t.album_cover,
                duration=t.duration
            ) for t in p.tracks
        ]
        response.append(PlaylistResponse(id=p.id, name=p.name, cover_image=p.cover_image, tracks=tracks))
    return response


@router.post("/playlists", response_model=PlaylistResponse, status_code=status.HTTP_201_CREATED)
async def create_playlist(
        data: PlaylistCreate,
        service: Annotated[MusicService, Depends(get_music_service)]
):
    return await service.create_playlist(data.name)


@router.delete("/playlists/{playlist_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_playlist(
        playlist_id: int,
        service: Annotated[MusicService, Depends(get_music_service)]
):
    await service.delete_playlist(playlist_id)


@router.post("/playlists/{playlist_id}/tracks")
async def add_track(
        playlist_id: int,
        track: TrackBase,
        service: Annotated[MusicService, Depends(get_music_service)]
):
    return await service.add_track_to_playlist(playlist_id, track)


@router.delete("/playlists/{playlist_id}/tracks/{track_id}")
async def remove_track(
        playlist_id: int,
        track_id: int,
        service: Annotated[MusicService, Depends(get_music_service)]
):
    return await service.remove_track_from_playlist(playlist_id, str(track_id))
