from config import settings

from .repositories import DabRepository
from .service import MusicService


def get_headers() -> dict:
    return {
        "User-Agent": settings.SECRET_USER_AGENT,
    }


async def get_dab_service() -> MusicService:
    headers = get_headers()
    repository = DabRepository(
        api_base_url=settings.DAB_API_URL,
        headers=headers,
    )
    service = MusicService(repository)
    try:
        yield service
    finally:
        await service.close()
