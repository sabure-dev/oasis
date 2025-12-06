from datetime import timedelta
from sqlalchemy.ext.asyncio import AsyncSession

from users.repository import UserRepository
from users.schemas import TokenResponse
from core.security import verify_password, create_token
from music.service import DabAuthService, DabSessionCache
from config import settings


class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repository = UserRepository()

    async def register(self, username: str, email: str, password: str) -> TokenResponse:
        existing_user = await self.repository.get_by_email(self.db, email)
        if existing_user:
            raise ValueError("Email already registered")

        existing_username = await self.repository.get_by_username(self.db, username)
        if existing_username:
            raise ValueError("Username already taken")

        await DabAuthService.register(username, email, password)

        user = await self.repository.create(self.db, username, email, password)

        dab_session = await DabAuthService.login(email, password)
        await DabSessionCache.set_session(user.id, dab_session)

        return self._generate_tokens(user.id)

    async def login(self, email: str, password: str) -> TokenResponse:
        user = await self.repository.get_by_email(self.db, email)

        if not user or not verify_password(password, user.hashed_password):
            raise ValueError("Invalid credentials")

        dab_session = await DabAuthService.login(email, password)

        await DabSessionCache.set_session(user.id, dab_session)

        return self._generate_tokens(user.id)

    async def logout(self, user_id: int):
        await DabSessionCache.invalidate(user_id)

    def _generate_tokens(self, user_id: int) -> TokenResponse:
        access_token = create_token(
            data={"sub": str(user_id)},
            expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
            token_type="access"
        )

        refresh_token = create_token(
            data={"sub": str(user_id)},
            expires_delta=timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
            token_type="refresh"
        )

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token
        )
