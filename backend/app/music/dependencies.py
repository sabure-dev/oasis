from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from music.service import MusicService
from users.dependencies import get_current_user
from users.models import User


async def get_music_service(
        user: User = Depends(get_current_user),
        db: AsyncSession = Depends(get_db)
) -> MusicService:
    return MusicService(user_id=user.id, db=db)
