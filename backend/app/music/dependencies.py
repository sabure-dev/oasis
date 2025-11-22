from config import settings

from .repositories import DabRepository
from .service import MusicService


def get_headers() -> dict:
    return {
        "User-Agent": settings.SECRET_USER_AGENT,
    }


def get_user_api_data() -> dict:
    return {
        "email": settings.PRIVATE_EMAIL,
        "password": settings.PRIVATE_PASSWORD,
    }


async def get_dab_service() -> MusicService:
    headers = get_headers()
    user_api_data = get_user_api_data()
    repository = DabRepository(
        api_base_url=settings.DAB_API_URL,
        user_api_data=user_api_data,
        headers=headers,
    )
    service = MusicService(repository)
    try:
        yield service
    finally:
        await service.close()
