from abc import ABC, abstractmethod

import aiohttp

from core.exceptions import UpstreamServiceError, InvalidToken


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
    def __init__(
            self,
            api_base_url: str,
            dab_session: str,
            headers: dict,
    ):
        self.api_base_url = api_base_url
        self.dab_session = dab_session
        self.headers = headers
        self._session: aiohttp.ClientSession | None = None

    async def _ensure_session(self):
        if self._session is None or self._session.closed:
            self._session = aiohttp.ClientSession(headers=self.headers)

    async def search_tracks(self, query: str, offset: int) -> list[dict]:
        await self._ensure_session()

        url = f"{self.api_base_url}/search"
        params = {"q": query, "offset": offset}
        cookies = {"session": self.dab_session}

        try:
            async with self._session.get(
                    url,
                    params=params,
                    cookies=cookies
            ) as response:
                if response.status == 401:
                    raise InvalidToken("DAB session expired")

                if response.status != 200:
                    return []

                data = await response.json()
        except aiohttp.ClientError as e:
            raise UpstreamServiceError(f"Search failed: {str(e)}")

        return [
            {
                "id": item.get("id", ""),
                "title": item.get("title", "Untitled"),
                "artist": item.get("artist", "Unknown"),
                "album": item.get("albumTitle", "Unknown"),
                "album_cover": item.get("albumCover", ""),
                "release_date": item.get("releaseDate", ""),
                "genre": item.get("genre", ""),
                "duration": item.get("duration", 0),
            }
            for item in data.get("tracks", [])
        ]

    async def stream_track(self, track_id: int) -> dict:
        await self._ensure_session()

        url = f"{self.api_base_url}/stream"
        params = {"trackId": track_id}
        cookies = {"session": self.dab_session}

        try:
            async with self._session.get(
                    url,
                    params=params,
                    cookies=cookies
            ) as response:
                if response.status == 401:
                    raise InvalidToken("DAB session expired")

                if response.status != 200:
                    text = await response.text()
                    raise UpstreamServiceError(
                        f"Stream failed with {response.status}: {text}"
                    )

                return await response.json()
        except aiohttp.ClientError as e:
            raise UpstreamServiceError(f"Stream connection failed: {str(e)}")

    async def close(self):
        if self._session and not self._session.closed:
            await self._session.close()
            self._session = None
