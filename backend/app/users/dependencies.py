from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from core.dependencies import get_current_user_id
from core.exceptions import UserNotFound, InvalidCredentials
from database import get_db
from users.models import User
from users.repository import UserRepository
from users.service import UserService


async def get_user_service(
        db: Annotated[AsyncSession, Depends(get_db)]
) -> UserService:
    return UserService(db)


async def get_current_user(
        user_id: Annotated[int, Depends(get_current_user_id)],
        db: Annotated[AsyncSession, Depends(get_db)]
) -> User:
    repository = UserRepository()
    user = await repository.get_by_id(db, user_id)
    if not user:
        raise UserNotFound()
    if not user.is_active:
        raise InvalidCredentials("User is inactive")
    return user
