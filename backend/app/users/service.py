from datetime import timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from core.exceptions import (
    UserAlreadyExists,
    InvalidCredentials,
    InvalidToken, UpstreamServiceError
)
from core.security import verify_password, create_token, decode_token
from music.service import DabAuthService, DabSessionCache
from users.repository import UserRepository
from users.schemas import TokenResponse


class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repository = UserRepository()

    async def register(self, username: str, email: str, password: str) -> TokenResponse:
        existing_user = await self.repository.get_by_email(self.db, email)
        if existing_user:
            raise UserAlreadyExists("Email already registered")

        existing_username = await self.repository.get_by_username(self.db, username)
        if existing_username:
            raise UserAlreadyExists("Username already taken")

        await DabAuthService.register(username, email, password)

        user = await self.repository.create(self.db, username, email, password)

        dab_session = await DabAuthService.login(email, password)
        await DabSessionCache.set_session(user.id, dab_session)

        return self._generate_tokens(user.id)

    async def login(self, email: str, password: str) -> TokenResponse:
        user = await self.repository.get_by_email(self.db, email)

        if not user or not verify_password(password, user.hashed_password):
            raise InvalidCredentials()

        dab_session = await DabAuthService.login(email, password)

        await DabSessionCache.set_session(user.id, dab_session)

        return self._generate_tokens(user.id)

    async def refresh_tokens(self, refresh_token: str, password: str) -> TokenResponse:
        payload = decode_token(refresh_token)

        if not payload or payload.get("type") != "refresh":
            raise InvalidToken("Invalid refresh token")

        user_id = int(payload.get("sub"))
        if not user_id:
            raise InvalidToken("Invalid token payload")

        user = await self.repository.get_by_id(self.db, user_id)
        if not user:
            raise InvalidToken("User not found")

        if not verify_password(password, user.hashed_password):
            raise InvalidCredentials()

        dab_session = await DabSessionCache.get_session(user_id)

        if not dab_session:
            try:
                new_dab_session = await DabAuthService.login(user.email, password)
                await DabSessionCache.set_session(user_id, new_dab_session)
            except Exception as e:
                raise UpstreamServiceError(f"Failed to refresh session: {str(e)}")

        return self._generate_tokens(user_id)

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
