from .repositories import MusicRepository


class MusicService:
    def __init__(self, repository: MusicRepository):
        self._repository = repository

    async def search_tracks(self, query: str, offset: int = 0) -> list[dict]:
        return await self._repository.search_tracks(query, offset)

    async def stream_track(self, track_id: int) -> dict:
        return await self._repository.stream_track(track_id)

    async def close(self):
        await self._repository.close()
