from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from core.security import hash_password
from users.models import User


class UserRepository:
    @staticmethod
    async def create(
            db: AsyncSession,
            username: str,
            email: str,
            password: str,
            ext_password_encrypted: str,
    ) -> User:
        hashed_password = hash_password(password)
        user = User(
            username=username,
            email=email,
            hashed_password=hashed_password,
            ext_password_encrypted=ext_password_encrypted,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user

    @staticmethod
    async def get_by_email(
            db: AsyncSession,
            email: str
    ) -> User | None:
        stmt = select(User).where(User.email == email)
        result = await db.execute(stmt)
        return result.scalar_one_or_none()

    @staticmethod
    async def get_by_username(
            db: AsyncSession,
            username: str
    ) -> User | None:
        stmt = select(User).where(User.username == username)
        result = await db.execute(stmt)
        return result.scalar_one_or_none()

    @staticmethod
    async def get_by_id(
            db: AsyncSession,
            user_id: int
    ) -> User | None:
        stmt = select(User).where(User.id == user_id)
        result = await db.execute(stmt)
        return result.scalar_one_or_none()
