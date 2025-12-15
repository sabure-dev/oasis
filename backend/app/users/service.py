import random
import uuid
from datetime import timedelta

from fastapi import BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from core.email import send_email
from core.encryption import encrypt_password, decrypt_password
from core.exceptions import (
    InvalidCredentials,
    InvalidToken, UpstreamServiceError
)
from core.security import verify_password, create_token, decode_token, hash_password
from music.service import DabAuthService, DabSessionCache
from redis_client import redis_client
from users.models import User
from users.repository import UserRepository
from users.schemas import TokenResponse


class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repository = UserRepository()

    async def register(self, username: str, email: str, password: str,
                       background_tasks: BackgroundTasks) -> TokenResponse:
        dab_password = str(uuid.uuid4()) + str(uuid.uuid4())

        await DabAuthService.register(username, email, dab_password)

        encrypted_ext_pass = encrypt_password(dab_password)

        user = await self.repository.create(
            self.db,
            username,
            email,
            password,
            ext_password_encrypted=encrypted_ext_pass
        )

        dab_session = await DabAuthService.login(email, dab_password)
        await DabSessionCache.set_session(user.id, dab_session)

        await self._send_verification_code(user, background_tasks)
        return self._generate_tokens(user.id)

    async def login(self, email: str, password: str) -> TokenResponse:
        user = await self.repository.get_by_email(self.db, email)

        if not user or not verify_password(password, user.hashed_password):
            raise InvalidCredentials()

        if not user.is_active:
            raise InvalidCredentials("User is inactive")

        ext_password_to_use = decrypt_password(user.ext_password_encrypted)

        dab_session = await DabAuthService.login(email, ext_password_to_use)

        await DabSessionCache.set_session(user.id, dab_session)

        return self._generate_tokens(user.id)

    async def refresh_tokens(self, refresh_token: str) -> TokenResponse:
        payload = decode_token(refresh_token)
        if not payload or payload.get("type") != "refresh":
            raise InvalidToken("Invalid refresh token")

        user_id = int(payload.get("sub"))
        if not user_id:
            raise InvalidToken("Invalid token payload")

        user = await self.repository.get_by_id(self.db, user_id)
        if not user:
            raise InvalidToken("User not found")

        if not user.is_active:
            raise InvalidCredentials("User is inactive")

        dab_session = await DabSessionCache.get_session(user_id)

        if not dab_session:
            ext_password_to_use = decrypt_password(user.ext_password_encrypted)

            try:
                new_dab_session = await DabAuthService.login(user.email, ext_password_to_use)
                await DabSessionCache.set_session(user_id, new_dab_session)
            except Exception as e:
                raise UpstreamServiceError(f"Failed to refresh session: {str(e)}")

        access_token = create_token(
            data={"sub": str(user_id)},
            expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
            token_type="access"
        )

        return TokenResponse(
            access_token=access_token,
            refresh_token=None
        )

    async def logout(self, user_id: int):
        await DabSessionCache.invalidate(user_id)

    async def request_verification(self, user_id: int, background_tasks: BackgroundTasks):
        user = await self.repository.get_by_id(self.db, user_id)
        if not user:
            raise InvalidToken("User not found")

        if user.is_verified:
            raise UpstreamServiceError("User already verified")

        await self._send_verification_code(user, background_tasks)

        return {"message": "Verification code sent"}

    async def _send_verification_code(self, user: User, background_tasks: BackgroundTasks):
        code = "".join([str(random.randint(0, 9)) for _ in range(6)])
        await redis_client.set(f"verification:{user.id}", code, ex=600)

        subject = "Oasis App Verification Code"
        body = f"Hello {user.username},\n\nYour verification code is: {code}\n\nThis code expires in 10 minutes."

        background_tasks.add_task(send_email, user.email, subject, body)

    async def verify_email(self, user_id: int, code: str):
        cached_code = await redis_client.get(f"verification:{user_id}")

        if not cached_code:
            raise InvalidCredentials("Verification code expired")

        if cached_code != code:
            raise InvalidCredentials("Invalid verification code")

        user = await self.repository.get_by_id(self.db, user_id)
        user.is_verified = True

        await self.db.commit()
        await self.db.refresh(user)

        await redis_client.delete(f"verification:{user_id}")

        return {"message": "Email verified successfully"}

    async def forgot_password(self, email: str, background_tasks: BackgroundTasks):
        user = await self.repository.get_by_email(self.db, email)
        if not user:
            raise InvalidCredentials("User with this email does not exist")

        code = "".join([str(random.randint(0, 9)) for _ in range(6)])

        await redis_client.set(f"reset:{email}", code, ex=600)

        subject = "Reset Your Password"
        body = f"Hello {user.username},\n\nYour password reset code is: {code}\n\nIf you did not request this, please ignore this email."

        background_tasks.add_task(send_email, email, subject, body)

        return {"message": "Reset code sent"}

    async def reset_password(self, email: str, code: str, new_password: str):
        cached_code = await redis_client.get(f"reset:{email}")

        if not cached_code:
            raise InvalidCredentials("Reset code expired or invalid")

        if cached_code != code:
            raise InvalidCredentials("Invalid reset code")

        user = await self.repository.get_by_email(self.db, email)
        if not user:
            raise InvalidCredentials("User not found")

        user.hashed_password = hash_password(new_password)

        await self.db.commit()

        await redis_client.delete(f"reset:{email}")

        await DabSessionCache.invalidate(user.id)

        return {"message": "Password updated successfully"}

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
