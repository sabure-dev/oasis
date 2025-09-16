from abc import ABC, abstractmethod

import aiohttp


class MusicRepository(ABC):
    @abstractmethod
    async def search_tracks(self, query: str, offset: int) -> list[dict]:
        pass

    @abstractmethod
    async def stream_track(self, track_id: int) -> dict:
        pass

    @abstractmethod
    async def close(self):
        pass


class DabRepository(MusicRepository):
    def __init__(self, api_base_url: str):
        self.api_base_url = api_base_url
        self._session = None

    async def start_session(self):
        if self._session is None or self._session.closed:
            self._session = aiohttp.ClientSession()

    async def search_tracks(self, query: str, offset: int) -> list[dict]:
        await self.start_session()

        url = f"{self.api_base_url}/search"
        params = {
            "q": query,
            "offset": offset,
        }

        async with self._session.get(url, params=params) as response:
            if response.status != 200:
                return []

            data = await response.json()

        formatted_tracks = []
        for item in data.get("tracks", []):
            formatted_tracks.append({
                "id": item.get("id", ""),
                "title": item.get("title", "Untitled"),
                "artist": item.get("artist", "Untitled"),
                "album": item.get("albumTitle", "Untitled"),
                "album_cover": item.get("albumCover", "Untitled"),
                "release_date": item.get("releaseDate", ""),
                "genre": item.get("genre", ""),
                "duration": item.get("duration", 0),
            })
        return formatted_tracks

    async def stream_track(self, track_id: int) -> dict:
        await self.start_session()

        url = f"{self.api_base_url}/stream"
        params = {"trackId": track_id}

        async with self._session.get(url, params=params) as response:
            if response.status != 200:
                raise Exception(f"Failed to stream track: {response.status}")

            data = await response.json()

        return data

    async def close(self):
        if self._session and not self._session.closed:
            await self._session.close()
