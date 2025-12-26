from pydantic import BaseModel
from typing import List, Optional


class TrackBase(BaseModel):
    id: int
    title: str
    artist: str
    album: Optional[str] = None
    album_cover: Optional[str] = None
    duration: int = 0

    class Config:
        from_attributes = True


class PlaylistCreate(BaseModel):
    name: str


class PlaylistResponse(BaseModel):
    id: int
    name: str
    cover_image: Optional[str] = None
    tracks: List[TrackBase] = []

    class Config:
        from_attributes = True
