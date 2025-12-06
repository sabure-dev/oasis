import aiohttp

from config import settings, DAB_SESSION_TTL_SECONDS
from music.repository import DabRepository
from redis_client import redis_client


class DabSessionCache:
    @staticmethod
    def _get_cache_key(user_id: int) -> str:
        return f"dab_session:{user_id}"

    @staticmethod
    async def get_session(user_id: int) -> str | None:
        cache_key = DabSessionCache._get_cache_key(user_id)
        return await redis_client.get(cache_key)

    @staticmethod
    async def set_session(user_id: int, session: str):
        cache_key = DabSessionCache._get_cache_key(user_id)
        await redis_client.set(cache_key, session, ex=DAB_SESSION_TTL_SECONDS)

    @staticmethod
    async def invalidate(user_id: int):
        cache_key = DabSessionCache._get_cache_key(user_id)
        await redis_client.delete(cache_key)


class DabAuthService:
    @staticmethod
    async def register(username: str, email: str, password: str):
        url = f"{settings.DAB_API_URL}/auth/register"
        user_data = {
            "username": username,
            "email": email,
            "password": password
        }
        headers = {"User-Agent": settings.SECRET_USER_AGENT}

        async with aiohttp.ClientSession() as session:
            async with session.post(
                    url,
                    json=user_data,
                    headers=headers
            ) as resp:
                if resp.status != 201:
                    text = await resp.text()
                    raise Exception(
                        f"DAB API registration failed {resp.status}: {text}"
                    )

    @staticmethod
    async def login(email: str, password: str) -> str:
        url = f"{settings.DAB_API_URL}/auth/login"
        user_data = {"email": email, "password": password}
        headers = {"User-Agent": settings.SECRET_USER_AGENT}

        async with aiohttp.ClientSession() as session:
            async with session.post(
                    url,
                    json=user_data,
                    headers=headers
            ) as resp:
                if resp.status != 200:
                    text = await resp.text()
                    raise Exception(
                        f"DAB API returned {resp.status}: {text}"
                    )

                session_cookie = resp.cookies.get("session")
                if not session_cookie:
                    raise Exception("No session cookie from DAB API")

                return session_cookie.value


class MusicService:
    def __init__(self, user_id: int):
        self.user_id = user_id
        self.repository: DabRepository | None = None

    async def _get_repository(self) -> DabRepository:
        if self.repository is None:
            dab_session = await DabSessionCache.get_session(self.user_id)

            if not dab_session:
                raise ValueError("DAB session expired, please login again")

            headers = {"User-Agent": settings.SECRET_USER_AGENT}

            self.repository = DabRepository(
                api_base_url=settings.DAB_API_URL,
                dab_session=dab_session,
                headers=headers,
            )

        return self.repository

    async def search_tracks(self, query: str, offset: int = 0) -> list[dict]:
        repo = await self._get_repository()
        return await repo.search_tracks(query, offset)

    async def stream_track(self, track_id: int) -> dict:
        repo = await self._get_repository()
        return await repo.stream_track(track_id)

    async def close(self):
        if self.repository:
            await self.repository.close()
