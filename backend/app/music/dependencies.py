from .repositories import DabRepository
from .service import MusicService


async def get_dab_service() -> MusicService:
    repository = DabRepository()
    service = MusicService(repository)
    try:
        yield service
    finally:
        await service.close()
