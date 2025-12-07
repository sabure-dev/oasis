from typing import Annotated
from fastapi import Depends, HTTPException, status

from music.service import MusicService
from core.dependencies import get_current_user_id


async def get_music_service(
    user_id: Annotated[int, Depends(get_current_user_id)]
) -> MusicService:
    service = MusicService(user_id)
    try:
        yield service
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    finally:
        await service.close()
