from config import settings
from .repositories import DabRepository
from .service import MusicService


async def get_dab_service() -> MusicService:
    repository = DabRepository(api_base_url=settings.DAB_API_URL)
    service = MusicService(repository)
    try:
        yield service
    finally:
        await service.close()
