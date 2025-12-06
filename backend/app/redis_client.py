from redis.asyncio import Redis
from config import settings


class RedisClient:
    def __init__(self):
        self._client: Redis | None = None

    async def connect(self):
        try:
            self._client = Redis.from_url(
                settings.REDIS_URL,
                decode_responses=True,
                encoding="utf-8"
            )
            await self._client.ping()
        except Exception as e:
            raise Exception(f"Failed to connect to Redis: {e}")

    async def disconnect(self):
        if self._client:
            await self._client.aclose()

    async def get(self, key: str) -> str | None:
        if not self._client:
            raise Exception("Redis client not connected")
        return await self._client.get(key)

    async def set(self, key: str, value: str, ex: int | None = None):
        if not self._client:
            raise Exception("Redis client not connected")
        await self._client.set(key, value, ex=ex)

    async def delete(self, key: str):
        if not self._client:
            raise Exception("Redis client not connected")
        await self._client.delete(key)


redis_client = RedisClient()
